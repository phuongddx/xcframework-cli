# frozen_string_literal: true

module XCFrameworkCLI
  module Builder
    # Archiver for creating platform-specific archives
    # Orchestrates archive creation using Platform and Xcodebuild classes
    class Archiver
      attr_reader :project_path, :scheme, :output_dir, :derived_data_path

      # Initialize archiver
      #
      # @param project_path [String] Path to .xcodeproj file
      # @param scheme [String] Scheme name to build
      # @param output_dir [String] Output directory for archives
      # @param derived_data_path [String, nil] Optional derived data path
      def initialize(project_path:, scheme:, output_dir:, derived_data_path: nil)
        @project_path = project_path
        @scheme = scheme
        @output_dir = output_dir
        @derived_data_path = derived_data_path || File.join(output_dir, 'DerivedData')
      end

      # Build archive for a platform
      #
      # @param platform_identifier [String] Platform identifier (e.g., 'ios', 'ios-simulator')
      # @param options [Hash] Build options
      # @option options [String] :deployment_target Deployment target version
      # @option options [Array<String>] :architectures Architectures to build
      # @return [Hash] Archive result with :success, :archive_path, :platform, :error
      # rubocop:disable Metrics/AbcSize
      def build_archive(platform_identifier, options = {})
        platform = Platform::Registry.create(platform_identifier)
        archive_suffix = archive_suffix_for_platform(platform_identifier)
        archive_path = File.join(output_dir, "#{scheme}-#{archive_suffix}")

        Utils::Logger.info("Building archive for #{platform.platform_name}...")

        # Get build settings from platform
        architectures = options[:architectures] || platform.valid_architectures
        deployment_target = options[:deployment_target] || platform.default_deployment_target

        build_settings = platform.build_settings(
          architectures: architectures,
          deployment_target: deployment_target
        )

        # Execute archive command
        result = Xcodebuild::Wrapper.execute_archive(
          project: project_path,
          scheme: scheme,
          destination: platform.destination,
          archive_path: archive_path,
          build_settings: build_settings,
          derived_data_path: derived_data_path
        )

        if result.success?
          # Clean private Swift interfaces
          clean_private_interfaces(archive_path)

          Utils::Logger.info("✓ Archive created: #{archive_path}.xcarchive")
          {
            success: true,
            archive_path: "#{archive_path}.xcarchive",
            platform: platform_identifier,
            platform_name: platform.platform_name
          }
        else
          Utils::Logger.error("✗ Archive failed for #{platform.platform_name}")
          Utils::Logger.error(result.error_message) if result.error_message
          {
            success: false,
            archive_path: nil,
            platform: platform_identifier,
            platform_name: platform.platform_name,
            error: result.error_message
          }
        end
      rescue StandardError => e
        Utils::Logger.error("Archive build failed: #{e.message}")
        {
          success: false,
          archive_path: nil,
          platform: platform_identifier,
          error: e.message
        }
      end
      # rubocop:enable Metrics/AbcSize

      # Build archives for multiple platforms
      #
      # @param platform_identifiers [Array<String>] List of platform identifiers
      # @param options [Hash] Build options
      # @return [Array<Hash>] List of archive results
      def build_archives(platform_identifiers, options = {})
        results = []
        platform_identifiers.each do |platform_id|
          result = build_archive(platform_id, options)
          results << result
        end
        results
      end

      # Verify archive exists
      #
      # @param archive_path [String] Path to archive
      # @return [Boolean] true if archive exists
      def archive_exists?(archive_path)
        File.directory?(archive_path)
      end

      # Get framework path within archive
      #
      # @param archive_path [String] Path to archive
      # @param framework_name [String] Framework name
      # @return [String, nil] Path to framework or nil if not found
      def framework_path_in_archive(archive_path, framework_name)
        path = File.join(
          archive_path,
          'Products/Library/Frameworks',
          "#{framework_name}.framework"
        )
        File.exist?(path) ? path : nil
      end

      # Get dSYM path within archive
      #
      # @param archive_path [String] Path to archive
      # @param framework_name [String] Framework name
      # @return [String, nil] Path to dSYM or nil if not found
      def dsym_path_in_archive(archive_path, framework_name)
        path = File.join(
          archive_path,
          'dSYMs',
          "#{framework_name}.framework.dSYM"
        )
        File.exist?(path) ? path : nil
      end

      private

      # Get archive suffix for platform
      #
      # @param platform_identifier [String] Platform identifier
      # @return [String] Archive suffix
      def archive_suffix_for_platform(platform_identifier)
        case platform_identifier
        when 'ios'
          'iOS'
        when 'ios-simulator'
          'iOS-Simulator'
        else
          platform_identifier
        end
      end

      # Clean private Swift interfaces from archive
      #
      # @param archive_path [String] Path to archive (without .xcarchive extension)
      def clean_private_interfaces(archive_path)
        swiftmodule_pattern = File.join(
          "#{archive_path}.xcarchive",
          'Products/Library/Frameworks',
          "#{scheme}.framework/Modules/#{scheme}.swiftmodule",
          '*.private.swiftinterface'
        )

        Dir.glob(swiftmodule_pattern).each do |file|
          File.delete(file)
          Utils::Logger.debug("Removed private interface: #{File.basename(file)}")
        end
      end
    end
  end
end
