# frozen_string_literal: true

require 'fileutils'

module XCFrameworkCLI
  module Builder
    # Cleaner for build artifacts and directories
    # Handles cleaning of archives, XCFrameworks, and derived data
    class Cleaner
      attr_reader :output_dir, :framework_name

      # Initialize cleaner
      #
      # @param output_dir [String] Output directory containing build artifacts
      # @param framework_name [String] Name of the framework
      def initialize(output_dir:, framework_name:)
        @output_dir = output_dir
        @framework_name = framework_name
      end

      # Clean all build artifacts
      #
      # @param options [Hash] Cleaning options
      # @option options [Boolean] :archives Clean archive files (default: true)
      # @option options [Boolean] :xcframework Clean XCFramework (default: true)
      # @option options [Boolean] :derived_data Clean derived data (default: false)
      # @return [Hash] Cleaning results
      def clean_all(options = {})
        defaults = { archives: true, xcframework: true, derived_data: false }
        opts = defaults.merge(options)

        results = {
          archives_cleaned: [],
          xcframework_cleaned: false,
          derived_data_cleaned: false,
          errors: []
        }

        results[:archives_cleaned] = clean_archives if opts[:archives]
        results[:xcframework_cleaned] = clean_xcframework if opts[:xcframework]
        results[:derived_data_cleaned] = clean_derived_data if opts[:derived_data]

        results
      rescue StandardError => e
        Utils::Logger.error("Cleaning failed: #{e.message}")
        results[:errors] << e.message
        results
      end

      # Clean archive files
      #
      # @return [Array<String>] List of cleaned archive paths
      def clean_archives
        cleaned = []
        archive_patterns.each do |pattern|
          Dir.glob(pattern).each do |path|
            next unless File.directory?(path)

            Utils::Logger.debug("Removing archive: #{path}")
            FileUtils.rm_rf(path)
            cleaned << path
          end
        end
        Utils::Logger.info("Cleaned #{cleaned.size} archive(s)") unless cleaned.empty?
        cleaned
      end

      # Clean XCFramework
      #
      # @return [Boolean] true if XCFramework was cleaned
      # rubocop:disable Naming/PredicateMethod
      def clean_xcframework
        xcframework_path = File.join(output_dir, "#{framework_name}.xcframework")
        return false unless File.exist?(xcframework_path)

        Utils::Logger.debug("Removing XCFramework: #{xcframework_path}")
        FileUtils.rm_rf(xcframework_path)
        Utils::Logger.info("Cleaned XCFramework: #{framework_name}.xcframework")
        true
      end
      # rubocop:enable Naming/PredicateMethod

      # Clean derived data
      #
      # @return [Boolean] true if derived data was cleaned
      # rubocop:disable Naming/PredicateMethod
      def clean_derived_data
        derived_data_path = File.join(output_dir, 'DerivedData')
        return false unless File.exist?(derived_data_path)

        Utils::Logger.debug("Removing derived data: #{derived_data_path}")
        FileUtils.rm_rf(derived_data_path)
        Utils::Logger.info('Cleaned derived data')
        true
      end
      # rubocop:enable Naming/PredicateMethod

      # Clean specific archive
      #
      # @param archive_path [String] Path to archive to clean
      # @return [Boolean] true if archive was cleaned
      # rubocop:disable Naming/PredicateMethod
      def clean_archive(archive_path)
        return false unless File.exist?(archive_path)

        Utils::Logger.debug("Removing archive: #{archive_path}")
        FileUtils.rm_rf(archive_path)
        true
      end
      # rubocop:enable Naming/PredicateMethod

      # Check if output directory exists
      #
      # @return [Boolean] true if output directory exists
      def output_dir_exists?
        File.directory?(output_dir)
      end

      # Create output directory if it doesn't exist
      #
      # @return [Boolean] true if directory was created or already exists
      def ensure_output_dir
        return true if output_dir_exists?

        Utils::Logger.debug("Creating output directory: #{output_dir}")
        FileUtils.mkdir_p(output_dir)
        true
      rescue StandardError => e
        Utils::Logger.error("Failed to create output directory: #{e.message}")
        false
      end

      private

      # Get archive file patterns
      #
      # @return [Array<String>] List of glob patterns for archives
      def archive_patterns
        [
          File.join(output_dir, "#{framework_name}-*.xcarchive"),
          File.join(output_dir, '*-iOS.xcarchive'),
          File.join(output_dir, '*-iOS-Simulator.xcarchive')
        ]
      end
    end
  end
end
