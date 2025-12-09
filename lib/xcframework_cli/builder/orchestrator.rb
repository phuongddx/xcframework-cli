# frozen_string_literal: true

module XCFrameworkCLI
  module Builder
    # Orchestrator for the complete XCFramework build process
    # Coordinates cleaning, archiving, and XCFramework creation
    class Orchestrator
      attr_reader :config

      # Initialize orchestrator
      #
      # @param config [Hash] Build configuration
      # @option config [String] :project_path Path to .xcodeproj file
      # @option config [String] :scheme Scheme name to build
      # @option config [String] :framework_name Framework name
      # @option config [String] :output_dir Output directory
      # @option config [Array<String>] :platforms Platform identifiers (default: ['ios', 'ios-simulator'])
      # @option config [Boolean] :clean Clean before build (default: true)
      # @option config [Boolean] :include_debug_symbols Include dSYM files (default: true)
      # @option config [String] :deployment_target Deployment target version
      def initialize(config)
        @config = validate_config(config)
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
    end
  end
end
