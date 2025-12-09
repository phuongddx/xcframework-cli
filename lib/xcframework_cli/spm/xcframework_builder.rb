# frozen_string_literal: true

require 'fileutils'
require 'tmpdir'

module XCFrameworkCLI
  module SPM
    # XCFramework builder from Swift Package
    # Combines multiple framework slices into .xcframework
    class XCFrameworkBuilder
      attr_reader :target, :sdks, :package_dir, :output_path, :configuration, :library_evolution

      # Initialize XCFramework builder
      #
      # @param target [String] Target name to build
      # @param sdks [Array<Swift::SDK>] Array of SDKs to build for
      # @param package_dir [String] Package directory
      # @param output_path [String] Output path for .xcframework
      # @param configuration [String] Build configuration
      # @param library_evolution [Boolean] Enable library evolution
      def initialize(target:, sdks:, package_dir:, output_path:, configuration: 'release', library_evolution: true)
        @target = target
        @sdks = sdks
        @package_dir = package_dir
        @output_path = output_path
        @configuration = configuration
        @library_evolution = library_evolution
        @slices = []
      end

      # Build XCFramework
      #
      # @return [Hash] Build result with :success, :xcframework_path, :slices, :error
      def build
        Utils::Logger.info("Building #{target}.xcframework for #{sdks.length} SDK(s)...")

        result = {
          success: false,
          xcframework_path: nil,
          slices: [],
          errors: []
        }

        Dir.mktmpdir("xcframework-#{target}-") do |tmpdir|
          # Step 1: Build framework slices for each SDK
          slice_results = build_framework_slices(tmpdir)
          result[:slices] = slice_results

          # Check if any slices succeeded
          successful_slices = slice_results.select { |s| s[:success] }
          if successful_slices.empty?
            result[:errors] << 'All framework slice builds failed'
            return result
          end

          # Step 2: Create XCFramework from slices
          xcframework_result = create_xcframework(successful_slices, tmpdir)

          if xcframework_result[:success]
            result[:success] = true
            result[:xcframework_path] = output_path
            Utils::Logger.success("✓ XCFramework created: #{output_path}")
          else
            result[:errors] << xcframework_result[:error]
          end
        end

        result
      rescue StandardError => e
        Utils::Logger.error("XCFramework build failed: #{e.message}")
        {
          success: false,
          xcframework_path: nil,
          slices: [],
          errors: [e.message]
        }
      end

      private

      # Build framework slices for all SDKs
      #
      # @param tmpdir [String] Temporary directory
      # @return [Array<Hash>] Array of slice build results
      def build_framework_slices(tmpdir)
        results = []

        sdks.each_with_index do |sdk, index|
          Utils::Logger.info("[#{index + 1}/#{sdks.length}] Building for #{sdk}...")

          slice_tmpdir = File.join(tmpdir, sdk.triple)
          FileUtils.mkdir_p(slice_tmpdir)

          framework_path = File.join(slice_tmpdir, "#{module_name}.framework")

          slice = FrameworkSlice.new(
            target: target,
            sdk: sdk,
            package_dir: package_dir,
            output_path: framework_path,
            configuration: configuration,
            library_evolution: library_evolution,
            tmpdir: slice_tmpdir
          )

          result = slice.build
          result[:sdk] = sdk
          results << result

          if result[:success]
            Utils::Logger.info("  ✓ Framework slice created for #{sdk}")
          else
            Utils::Logger.error("  ✗ Framework slice failed for #{sdk}: #{result[:error]}")
          end
        end

        results
      end

      # Create XCFramework from framework slices
      #
      # @param slice_results [Array<Hash>] Successful slice results
      # @param tmpdir [String] Temporary directory
      # @return [Hash] XCFramework creation result
      def create_xcframework(slice_results, tmpdir)
        Utils::Logger.info("Assembling XCFramework from #{slice_results.length} framework(s)...")

        # Group slices by SDK name (e.g., iphoneos, iphonesimulator)
        # This groups multi-architecture builds for the same platform
        grouped_slices = group_slices_by_platform(slice_results)

        # Create combined frameworks for multi-architecture platforms
        combined_frameworks = create_combined_frameworks(grouped_slices, tmpdir)

        # Ensure output directory exists
        FileUtils.mkdir_p(File.dirname(output_path))

        # Remove existing xcframework if it exists
        FileUtils.rm_rf(output_path) if File.exist?(output_path)

        # Build xcodebuild command
        cmd = build_xcframework_command(combined_frameworks)

        Utils::Logger.debug("Executing: #{cmd.join(' ')}")

        require 'open3'
        stdout, stderr, status = Open3.capture3(*cmd)

        if status.success?
          {
            success: true,
            xcframework_path: output_path
          }
        else
          {
            success: false,
            error: "xcodebuild -create-xcframework failed: #{stderr}"
          }
        end
      end

      # Group slices by SDK name (platform)
      #
      # @param slice_results [Array<Hash>] Slice results
      # @return [Hash] Grouped slices { sdk_name => [slice1, slice2, ...] }
      def group_slices_by_platform(slice_results)
        slice_results.group_by { |slice| slice[:sdk].sdk_name }
      end

      # Create combined frameworks for multi-architecture platforms
      #
      # @param grouped_slices [Hash] Slices grouped by platform
      # @param tmpdir [String] Temporary directory
      # @return [Array<Hash>] Combined framework results
      def create_combined_frameworks(grouped_slices, tmpdir)
        combined = []

        grouped_slices.each do |sdk_name, slices|
          if slices.length == 1
            # Single architecture - use as is
            combined << slices.first
          else
            # Multiple architectures - create fat binary
            combined_framework = combine_architectures(slices, sdk_name, tmpdir)
            combined << combined_framework if combined_framework
          end
        end

        combined
      end

      # Combine multiple architecture frameworks into one fat binary
      #
      # @param slices [Array<Hash>] Framework slices for same platform
      # @param sdk_name [String] SDK name
      # @param tmpdir [String] Temporary directory
      # @return [Hash, nil] Combined framework result
      def combine_architectures(slices, sdk_name, tmpdir)
        Utils::Logger.info("  Combining #{slices.length} architectures for #{sdk_name}...")

        # Create combined framework directory
        combined_dir = File.join(tmpdir, "combined-#{sdk_name}")
        combined_framework_path = File.join(combined_dir, "#{module_name}.framework")
        FileUtils.mkdir_p(combined_framework_path)

        # Copy framework structure from first slice
        first_slice = slices.first
        first_framework = first_slice[:framework_path]

        # Copy Info.plist, Headers, Modules from first framework
        %w[Info.plist Headers Modules].each do |item|
          src = File.join(first_framework, item)
          dst = File.join(combined_framework_path, item)
          if File.exist?(src)
            FileUtils.cp_r(src, dst)
          end
        end

        # Use lipo to combine binaries
        binary_name = module_name
        combined_binary = File.join(combined_framework_path, binary_name)
        input_binaries = slices.map { |s| File.join(s[:framework_path], binary_name) }

        lipo_cmd = ['lipo', '-create'] + input_binaries + ['-output', combined_binary]
        Utils::Logger.debug("Executing: #{lipo_cmd.join(' ')}")

        require 'open3'
        stdout, stderr, status = Open3.capture3(*lipo_cmd)

        unless status.success?
          Utils::Logger.error("  ✗ Failed to create fat binary: #{stderr}")
          return nil
        end

        Utils::Logger.info("  ✓ Created fat binary for #{sdk_name}")

        {
          success: true,
          framework_path: combined_framework_path,
          sdk: first_slice[:sdk]
        }
      end

      # Build xcodebuild -create-xcframework command
      #
      # @param slice_results [Array<Hash>] Slice results
      # @return [Array<String>] Command array
      def build_xcframework_command(slice_results)
        cmd = ['xcodebuild', '-create-xcframework']

        # Add -allow-internal-distribution if not using library evolution
        # This allows frameworks without stable module interfaces
        unless library_evolution
          cmd << '-allow-internal-distribution'
        end

        # Add framework paths
        slice_results.each do |result|
          cmd << '-framework' << result[:framework_path]
        end

        # Add output path
        cmd << '-output' << output_path

        cmd
      end

      # Get module name (C99-compatible)
      #
      # @return [String] Module name
      def module_name
        @module_name ||= target.gsub(/[^a-zA-Z0-9_]/, '_')
      end

      class << self
        # Build XCFramework for platforms
        #
        # @param target [String] Target name
        # @param platforms [Array<String>] Platform identifiers
        # @param package_dir [String] Package directory
        # @param output_dir [String] Output directory
        # @param options [Hash] Build options
        # @return [Hash] Build result
        def build_for_platforms(target:, platforms:, package_dir:, output_dir:, **options)
          # Convert platforms to SDKs
          all_sdks = platforms.flat_map do |platform_id|
            version = options[:version]
            Swift::SDK.sdks_for_platform(platform_id, version: version)
          end

          output_path = File.join(output_dir, "#{target}.xcframework")

          builder = new(
            target: target,
            sdks: all_sdks,
            package_dir: package_dir,
            output_path: output_path,
            configuration: options[:configuration] || 'release',
            library_evolution: options.fetch(:library_evolution, true)
          )

          builder.build
        end
      end
    end
  end
end
