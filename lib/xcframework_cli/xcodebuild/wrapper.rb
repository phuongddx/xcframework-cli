# frozen_string_literal: true

require 'open3'
require_relative 'result'
require_relative 'formatter'

module XCFrameworkCLI
  module Xcodebuild
    # Wrapper for executing xcodebuild commands
    # Handles command construction, execution, and error handling
    class Wrapper
      # Execute xcodebuild archive command
      #
      # @param options [Hash] Archive options
      # @option options [String] :project Path to .xcodeproj file
      # @option options [String] :scheme Scheme name to build
      # @option options [String] :destination Build destination (e.g., "generic/platform=iOS")
      # @option options [String] :archive_path Path where archive will be created
      # @option options [String] :configuration Build configuration (Debug or Release)
      # @option options [Hash] :build_settings Additional build settings (default: {})
      # @option options [String, nil] :derived_data_path Optional derived data path
      # @option options [Boolean, String] :use_formatter Use output formatter (default: true)
      # @return [Result] Command execution result
      def self.execute_archive(options)
        args = ['archive']
        args += ['-project', options[:project]]
        args += ['-scheme', options[:scheme]]
        args += ['-destination', options[:destination]]
        args += ['-archivePath', options[:archive_path]]
        args += ['-configuration', options[:configuration]] if options[:configuration]
        args += ['-derivedDataPath', options[:derived_data_path]] if options[:derived_data_path]

        # Add build settings
        build_settings = options[:build_settings] || {}
        build_settings.each do |key, value|
          args << "#{key}=#{value}"
        end

        execute_options = {}
        execute_options[:use_formatter] = options[:use_formatter] if options.key?(:use_formatter)

        execute('xcodebuild', args, execute_options)
      end

      # Execute xcodebuild -create-xcframework command
      #
      # @param frameworks [Array<Hash>] Array of framework hashes with :path and optional :debug_symbols
      # @param output [String] Output path for the XCFramework
      # @param use_formatter [Boolean, String] Use output formatter (default: true)
      # @return [Result] Command execution result
      def self.execute_create_xcframework(frameworks:, output:, use_formatter: true)
        args = ['-create-xcframework']

        frameworks.each do |framework|
          args += ['-framework', framework[:path]]
          args += ['-debug-symbols', framework[:debug_symbols]] if framework[:debug_symbols]
        end

        args += ['-output', output]

        execute('xcodebuild', args, { use_formatter: use_formatter })
      end

      # Execute xcodebuild clean command
      #
      # @param project [String] Path to .xcodeproj file
      # @param scheme [String] Scheme name to clean
      # @param derived_data_path [String, nil] Optional derived data path
      # @return [Result] Command execution result
      def self.execute_clean(project:, scheme:, derived_data_path: nil)
        args = ['clean']
        args += ['-project', project]
        args += ['-scheme', scheme]
        args += ['-derivedDataPath', derived_data_path] if derived_data_path

        execute('xcodebuild', args)
      end

      # Execute a generic xcodebuild command
      #
      # @param command [String] Command to execute
      # @param args [Array<String>] Command arguments
      # @param options [Hash] Execution options
      # @option options [Boolean] :stream_output Stream output in real-time (default: verbose mode)
      # @option options [Boolean, String] :use_formatter Use output formatter (default: true)
      # @return [Result] Command execution result
      def self.execute(command, args, options = {})
        full_command = [command] + args
        command_string = full_command.join(' ')

        Utils::Logger.debug("Executing: #{command_string}")

        # Determine if we should stream output (default to verbose mode)
        stream_output = options.fetch(:stream_output, Utils::Logger.verbose)
        use_formatter = options.fetch(:use_formatter, true)

        # Execute with formatter if streaming
        result_hash = Formatter.execute_with_formatting(
          full_command,
          stream_output: stream_output,
          use_formatter: stream_output ? use_formatter : false
        )

        result = Result.new(
          success: result_hash[:success],
          stdout: result_hash[:stdout],
          stderr: result_hash[:stderr],
          exit_code: result_hash[:exit_code],
          command: command_string
        )

        if result.failure?
          Utils::Logger.error("Command failed: #{command_string}")
          Utils::Logger.error("Exit code: #{result.exit_code}")
          # Only show error output if we didn't already stream it
          unless stream_output
            Utils::Logger.error("Error output: #{result.error_message}") unless result.error_message.empty?
          end
        else
          Utils::Logger.debug("Command succeeded: #{command_string}")
        end

        result
      end

      # Check if xcodebuild is available
      #
      # @return [Boolean] true if xcodebuild is available
      def self.available?
        execute('which', ['xcodebuild']).success?
      end

      # Get xcodebuild version
      #
      # @return [String, nil] Version string or nil if not available
      def self.version
        result = execute('xcodebuild', ['-version'])
        return nil unless result.success?

        # Parse version from output like "Xcode 15.0\nBuild version 15A240d"
        result.stdout.lines.first&.strip
      end

      # Get SDK path for a given SDK name
      #
      # @param sdk_name [String] SDK name (e.g., "iphoneos", "iphonesimulator")
      # @return [String, nil] SDK path or nil if not found
      def self.sdk_path(sdk_name)
        result = execute('xcrun', ['--sdk', sdk_name, '--show-sdk-path'])
        return nil unless result.success?

        result.stdout.strip
      end

      # List available SDKs
      #
      # @return [Array<String>] List of SDK names
      def self.list_sdks
        result = execute('xcodebuild', ['-showsdks'])
        return [] unless result.success?

        # Parse SDK names from output
        result.stdout.scan(/-sdk\s+(\S+)/).flatten
      end
    end
  end
end
