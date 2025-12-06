# frozen_string_literal: true

module XCFrameworkCLI
  module Builder
    # XCFramework builder
    # Orchestrates XCFramework creation from multiple archives
    class XCFramework
      attr_reader :framework_name, :output_dir

      # Initialize XCFramework builder
      #
      # @param framework_name [String] Name of the framework
      # @param output_dir [String] Output directory for XCFramework
      def initialize(framework_name:, output_dir:)
        @framework_name = framework_name
        @output_dir = output_dir
      end

      # Create XCFramework from archives
      #
      # @param archive_results [Array<Hash>] List of archive results from Archiver
      # @param options [Hash] Creation options
      # @option options [Boolean] :include_debug_symbols Include dSYM files (default: true)
      # @return [Hash] Creation result with :success, :xcframework_path, :error
      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      def create_xcframework(archive_results, options = {})
        include_dsyms = options.fetch(:include_debug_symbols, true)

        # Filter successful archives
        successful_archives = archive_results.select { |r| r[:success] }

        if successful_archives.empty?
          return {
            success: false,
            xcframework_path: nil,
            error: 'No successful archives to create XCFramework from'
          }
        end

        Utils::Logger.info("Creating XCFramework from #{successful_archives.size} archive(s)...")

        # Build frameworks array for xcodebuild
        frameworks = successful_archives.map do |archive_result|
          archive_path = archive_result[:archive_path]
          framework_path = locate_framework_in_archive(archive_path)

          unless framework_path
            Utils::Logger.warning("Framework not found in archive: #{archive_path}")
            next nil
          end

          framework_info = { path: framework_path }

          # Add debug symbols if requested and available
          if include_dsyms
            dsym_path = locate_dsym_in_archive(archive_path)
            framework_info[:debug_symbols] = dsym_path if dsym_path
          end

          framework_info
        end.compact

        if frameworks.empty?
          return {
            success: false,
            xcframework_path: nil,
            error: 'No frameworks found in archives'
          }
        end

        # Create XCFramework
        xcframework_path = File.join(output_dir, "#{framework_name}.xcframework")

        result = Xcodebuild::Wrapper.execute_create_xcframework(
          frameworks: frameworks,
          output: xcframework_path
        )

        if result.success?
          Utils::Logger.info("✓ XCFramework created: #{xcframework_path}")
          {
            success: true,
            xcframework_path: xcframework_path,
            frameworks_count: frameworks.size
          }
        else
          Utils::Logger.error('✗ XCFramework creation failed')
          Utils::Logger.error(result.error_message) if result.error_message
          {
            success: false,
            xcframework_path: nil,
            error: result.error_message
          }
        end
      rescue StandardError => e
        Utils::Logger.error("XCFramework creation failed: #{e.message}")
        {
          success: false,
          xcframework_path: nil,
          error: e.message
        }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

      # Verify XCFramework exists
      #
      # @param xcframework_path [String] Path to XCFramework
      # @return [Boolean] true if XCFramework exists
      def xcframework_exists?(xcframework_path)
        File.directory?(xcframework_path)
      end

      # Get XCFramework info
      #
      # @param xcframework_path [String] Path to XCFramework
      # @return [Hash, nil] XCFramework info or nil if not found
      def xcframework_info(xcframework_path)
        return nil unless xcframework_exists?(xcframework_path)

        info_plist = File.join(xcframework_path, 'Info.plist')
        return nil unless File.exist?(info_plist)

        {
          path: xcframework_path,
          name: framework_name,
          info_plist: info_plist,
          size: directory_size(xcframework_path)
        }
      end

      private

      # Locate framework in archive
      #
      # @param archive_path [String] Path to archive
      # @return [String, nil] Path to framework or nil if not found
      def locate_framework_in_archive(archive_path)
        framework_path = File.join(
          archive_path,
          'Products/Library/Frameworks',
          "#{framework_name}.framework"
        )
        File.exist?(framework_path) ? framework_path : nil
      end

      # Locate dSYM in archive
      #
      # @param archive_path [String] Path to archive
      # @return [String, nil] Path to dSYM or nil if not found
      def locate_dsym_in_archive(archive_path)
        dsym_path = File.join(
          archive_path,
          'dSYMs',
          "#{framework_name}.framework.dSYM"
        )
        File.exist?(dsym_path) ? dsym_path : nil
      end

      # Calculate directory size
      #
      # @param path [String] Directory path
      # @return [Integer] Size in bytes
      def directory_size(path)
        total = 0
        Dir.glob(File.join(path, '**', '*')).each do |file|
          total += File.size(file) if File.file?(file)
        end
        total
      end
    end
  end
end
