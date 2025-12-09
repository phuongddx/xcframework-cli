# frozen_string_literal: true

module XCFrameworkCLI
  module Builder
    # Orchestrator for the complete XCFramework build process
    # Coordinates cleaning, archiving, and XCFramework creation
    class Orchestrator
      attr_reader :config

      # Initialize orchestrator
      #
      # @param config [Hash] Build configuration (optional for SPM builds)
      # @option config [String] :project_path Path to .xcodeproj file
      # @option config [String] :scheme Scheme name to build
      # @option config [String] :framework_name Framework name
      # @option config [String] :output_dir Output directory
      # @option config [Array<String>] :platforms Platform identifiers (default: ['ios', 'ios-simulator'])
      # @option config [Boolean] :clean Clean before build (default: true)
      # @option config [Boolean] :include_debug_symbols Include dSYM files (default: true)
      # @option config [String] :deployment_target Deployment target version
      def initialize(config = {})
        @config = config.empty? ? {} : validate_config(config)
      end

      # Execute the complete build process
      #
      # @return [Hash] Build result with :success, :xcframework_path, :archives, :errors
      # rubocop:disable Metrics/AbcSize
      def build
        result = {
          success: false,
          xcframework_path: nil,
          archives: [],
          errors: [],
          steps_completed: []
        }

        begin
          # Step 1: Clean (if requested)
          if config[:clean]
            clean_result = clean_build_artifacts
            result[:steps_completed] << 'clean'
            result[:clean_result] = clean_result
          end

          # Step 2: Ensure output directory exists
          ensure_output_directory

          # Step 3: Build archives for each platform
          Utils::Logger.info("Building archives for platforms: #{config[:platforms].join(', ')}")
          archive_results = build_platform_archives
          result[:archives] = archive_results
          result[:steps_completed] << 'archive'

          # Check if any archives succeeded
          successful_archives = archive_results.select { |r| r[:success] }
          if successful_archives.empty?
            result[:errors] << 'All archive builds failed'
            return result
          end

          # Step 4: Create XCFramework
          Utils::Logger.info('Creating XCFramework...')
          xcframework_result = create_xcframework_from_archives(archive_results)
          result[:xcframework_result] = xcframework_result
          result[:steps_completed] << 'xcframework'

          if xcframework_result[:success]
            result[:success] = true
            result[:xcframework_path] = xcframework_result[:xcframework_path]
            Utils::Logger.info('✓ Build completed successfully!')
            Utils::Logger.info("  XCFramework: #{xcframework_result[:xcframework_path]}")
          else
            result[:errors] << xcframework_result[:error]
          end

          result
        rescue StandardError => e
          Utils::Logger.error("Build failed: #{e.message}")
          result[:errors] << e.message
          result
        end
      end
      # rubocop:enable Metrics/AbcSize

      # Build archives only (without creating XCFramework)
      #
      # @return [Array<Hash>] Archive results
      def build_archives_only
        ensure_output_directory
        build_platform_archives
      end

      # Create XCFramework from existing archives
      #
      # @param archive_paths [Array<String>] Paths to existing archives
      # @return [Hash] XCFramework creation result
      def create_xcframework_from_existing_archives(archive_paths)
        archive_results = archive_paths.map do |path|
          {
            success: File.directory?(path),
            archive_path: path,
            platform: extract_platform_from_path(path)
          }
        end

        create_xcframework_from_archives(archive_results)
      end

      private

      # Validate configuration
      #
      # @param config [Hash] Configuration to validate
      # @return [Hash] Validated configuration with defaults
      def validate_config(config)
        # Convert to regular hash if it's a Thor hash
        config_hash = config.to_h

        required_keys = %i[project_path scheme framework_name output_dir]
        missing_keys = required_keys - config_hash.keys

        unless missing_keys.empty?
          raise ArgumentError, "Missing required configuration keys: #{missing_keys.join(', ')}"
        end

        defaults = {
          platforms: %w[ios ios-simulator],
          clean: true,
          include_debug_symbols: true,
          deployment_target: nil
        }

        defaults.merge(config_hash)
      end

      # Clean build artifacts
      #
      # @return [Hash] Cleaning results
      def clean_build_artifacts
        Utils::Logger.info('Cleaning build artifacts...')
        cleaner = Cleaner.new(
          output_dir: config[:output_dir],
          framework_name: config[:framework_name]
        )
        cleaner.clean_all(archives: true, xcframework: true, derived_data: false)
      end

      # Ensure output directory exists
      def ensure_output_directory
        cleaner = Cleaner.new(
          output_dir: config[:output_dir],
          framework_name: config[:framework_name]
        )
        cleaner.ensure_output_dir
      end

      # Build archives for all configured platforms
      #
      # @return [Array<Hash>] Archive results
      def build_platform_archives
        archiver = Archiver.new(
          project_path: config[:project_path],
          scheme: config[:scheme],
          output_dir: config[:output_dir],
          configuration: config[:configuration] || 'Release',
          build_settings: config[:build_settings] || {}
        )

        build_options = {}
        build_options[:deployment_target] = config[:deployment_target] if config[:deployment_target]
        build_options[:use_formatter] = config[:use_formatter] if config.key?(:use_formatter)

        archiver.build_archives(config[:platforms], build_options)
      end

      # Create XCFramework from archive results
      #
      # @param archive_results [Array<Hash>] Archive results
      # @return [Hash] XCFramework creation result
      def create_xcframework_from_archives(archive_results)
        xcframework_builder = XCFramework.new(
          framework_name: config[:framework_name],
          output_dir: config[:output_dir]
        )

        xcframework_builder.create_xcframework(
          archive_results,
          include_debug_symbols: config[:include_debug_symbols]
        )
      end

      # Extract platform identifier from archive path
      #
      # @param path [String] Archive path
      # @return [String] Platform identifier
      def extract_platform_from_path(path)
        return 'ios' if path.include?('-iOS.xcarchive')
        return 'ios-simulator' if path.include?('-iOS-Simulator.xcarchive')

        'unknown'
      end

      public

      # Build XCFramework from Swift Package Manager (SPM)
      #
      # @param spm_config [Hash] SPM build configuration
      # @option spm_config [String] :package_dir Path to Package.swift directory
      # @option spm_config [Array<String>] :targets Target names to build
      # @option spm_config [Array<String>] :platforms Platform identifiers (default: ['ios', 'ios-simulator'])
      # @option spm_config [String] :output_dir Output directory
      # @option spm_config [String] :configuration Build configuration (default: 'release')
      # @option spm_config [Boolean] :library_evolution Enable library evolution (default: true)
      # @option spm_config [String] :version Platform version
      # @return [Hash] Build result with :success, :xcframework_paths, :errors
      def spm_build(spm_config)
        result = {
          success: false,
          xcframework_paths: [],
          errors: [],
          targets_completed: []
        }

        begin
          # Step 1: Validate Package.swift exists
          validate_spm_package(spm_config[:package_dir])

          # Step 2: Load package descriptor
          package = SPM::Package.new(spm_config[:package_dir])
          targets = spm_config[:targets] || package.library_targets.map(&:name)

          if targets.empty?
            result[:errors] << 'No targets specified for build'
            return result
          end

          Utils::Logger.info("Building #{targets.length} SPM target(s)...")

          # Step 3: Build each target
          targets.each_with_index do |target_name, index|
            Utils::Logger.info("[#{index + 1}/#{targets.length}] Building target: #{target_name}")

            # Verify target exists
            target = package.target(target_name)
            unless target
              Utils::Logger.warning("Target '#{target_name}' not found in package, skipping...")
              next
            end

            # Skip non-library targets
            unless target.library?
              Utils::Logger.warning("Target '#{target_name}' is not a library target, skipping...")
              next
            end

            # Step 3a: Determine SDKs from platforms
            platforms = spm_config[:platforms] || %w[ios ios-simulator]
            version = spm_config[:version] || package.platform_version('ios')

            # Step 3b: Build XCFramework using XCFrameworkBuilder
            xcf_result = SPM::XCFrameworkBuilder.build_for_platforms(
              target: target_name,
              platforms: platforms,
              package_dir: spm_config[:package_dir],
              output_dir: spm_config[:output_dir],
              configuration: spm_config[:configuration] || 'release',
              library_evolution: spm_config.fetch(:library_evolution, true),
              version: version
            )

            if xcf_result[:success]
              result[:xcframework_paths] << xcf_result[:xcframework_path]
              result[:targets_completed] << target_name
              Utils::Logger.success("✓ XCFramework created: #{xcf_result[:xcframework_path]}")
            else
              error_msg = "Target '#{target_name}' failed: #{xcf_result[:errors].join(', ')}"
              result[:errors] << error_msg
              Utils::Logger.error("✗ #{error_msg}")
            end
          end

          # Mark success if at least one target succeeded
          result[:success] = !result[:xcframework_paths].empty?

          if result[:success]
            Utils::Logger.success("Build completed! Created #{result[:xcframework_paths].length} XCFramework(s)")
          else
            Utils::Logger.error('All targets failed to build')
          end

          result
        rescue StandardError => e
          Utils::Logger.error("SPM build failed: #{e.message}")
          result[:errors] << e.message
          result
        end
      end

      private

      # Validate SPM package directory
      #
      # @param package_dir [String] Package directory path
      # @raise [ValidationError] if Package.swift not found
      def validate_spm_package(package_dir)
        package_swift = File.join(package_dir, 'Package.swift')
        return if File.exist?(package_swift)

        raise ValidationError.new(
          "No Package.swift found in #{package_dir}",
          suggestions: [
            'Ensure you are in a Swift Package directory',
            'Check the package_dir path in your configuration'
          ]
        )
      end
    end
  end
end
