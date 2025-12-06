# frozen_string_literal: true

require 'open3'

module XCFrameworkCLI
  module Xcodebuild
    # Formatter for xcodebuild output
    # Detects and uses xcbeautify or xcpretty if available
    class Formatter
      FORMATTERS = %w[xcbeautify xcpretty].freeze

      class << self
        # Check which formatter is available
        #
        # @return [String, nil] Name of available formatter or nil
        def detect_formatter
          FORMATTERS.find { |formatter| command_available?(formatter) }
        end

        # Check if a command is available in PATH
        #
        # @param command [String] Command name
        # @return [Boolean] true if command is available
        def command_available?(command)
          !`which #{command}`.strip.empty?
        rescue StandardError
          false
        end

        # Get formatter command with options
        #
        # @param formatter [String, nil] Formatter name ('xcbeautify', 'xcpretty', or nil)
        # @return [Array<String>, nil] Formatter command with args, or nil if no formatter
        def formatter_command(formatter = nil)
          case formatter
          when 'xcbeautify'
            ['xcbeautify']
          when 'xcpretty'
            ['xcpretty', '--color']
          else
            nil
          end
        end

        # Execute xcodebuild command with optional output formatting
        #
        # @param xcodebuild_command [Array<String>] Full xcodebuild command with arguments
        # @param stream_output [Boolean] Whether to stream output in real-time
        # @param use_formatter [Boolean, String] true to auto-detect, String to specify formatter, false to disable
        # @return [Hash] Result hash with :success, :stdout, :stderr, :exit_code
        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def execute_with_formatting(xcodebuild_command, stream_output: false, use_formatter: true)
          # Determine formatter to use
          formatter = if use_formatter == false
                        nil
                      elsif use_formatter.is_a?(String)
                        use_formatter if command_available?(use_formatter)
                      else
                        detect_formatter
                      end

          if stream_output && formatter
            execute_with_pipe_streaming(xcodebuild_command, formatter)
          elsif stream_output
            execute_with_streaming(xcodebuild_command)
          else
            execute_without_streaming(xcodebuild_command)
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        private

        # Execute with formatter pipe and real-time streaming
        #
        # @param xcodebuild_command [Array<String>] xcodebuild command
        # @param formatter [String] Formatter name
        # @return [Hash] Result hash
        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        def execute_with_pipe_streaming(xcodebuild_command, formatter)
          formatter_cmd = formatter_command(formatter)
          stdout_lines = []
          stderr_lines = []

          Utils::Logger.debug("Using formatter: #{formatter}")

          # Pipe xcodebuild through formatter
          Open3.popen3(*xcodebuild_command) do |_stdin, xcode_stdout, xcode_stderr, xcode_wait_thr|
            Open3.popen3(*formatter_cmd) do |formatter_stdin, formatter_stdout, _formatter_stderr, formatter_wait_thr|
              # Thread to pipe xcodebuild stdout to formatter stdin
              pipe_thread = Thread.new do
                xcode_stdout.each_line do |line|
                  formatter_stdin.puts(line)
                end
                formatter_stdin.close
              end

              # Thread to capture and stream formatted output
              stdout_thread = Thread.new do
                formatter_stdout.each_line do |line|
                  puts line # Print to console
                  stdout_lines << line
                end
              end

              # Thread to capture stderr
              stderr_thread = Thread.new do
                xcode_stderr.each_line do |line|
                  warn line # Print to stderr
                  stderr_lines << line
                end
              end

              # Wait for all threads
              pipe_thread.join
              stdout_thread.join
              stderr_thread.join

              xcode_status = xcode_wait_thr.value
              formatter_wait_thr.value # Wait for formatter to finish

              {
                success: xcode_status.success?,
                stdout: stdout_lines.join,
                stderr: stderr_lines.join,
                exit_code: xcode_status.exitstatus
              }
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        # Execute with real-time streaming (no formatter)
        #
        # @param command [Array<String>] Command to execute
        # @return [Hash] Result hash
        def execute_with_streaming(command)
          stdout_lines = []
          stderr_lines = []

          Open3.popen3(*command) do |_stdin, stdout, stderr, wait_thr|
            # Stream stdout
            stdout_thread = Thread.new do
              stdout.each_line do |line|
                puts line
                stdout_lines << line
              end
            end

            # Stream stderr
            stderr_thread = Thread.new do
              stderr.each_line do |line|
                warn line
                stderr_lines << line
              end
            end

            stdout_thread.join
            stderr_thread.join
            status = wait_thr.value

            {
              success: status.success?,
              stdout: stdout_lines.join,
              stderr: stderr_lines.join,
              exit_code: status.exitstatus
            }
          end
        end

        # Execute without streaming (capture all output)
        #
        # @param command [Array<String>] Command to execute
        # @return [Hash] Result hash
        def execute_without_streaming(command)
          stdout, stderr, status = Open3.capture3(*command)

          {
            success: status.success?,
            stdout: stdout,
            stderr: stderr,
            exit_code: status.exitstatus
          }
        end
      end
    end
  end
end
