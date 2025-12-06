# frozen_string_literal: true

module XCFrameworkCLI
  module Xcodebuild
    # Result object for xcodebuild command execution
    # Encapsulates success/failure status, output, and error information
    class Result
      attr_reader :success, :stdout, :stderr, :exit_code, :command

      def initialize(success:, stdout: '', stderr: '', exit_code: 0, command: '')
        @success = success
        @stdout = stdout
        @stderr = stderr
        @exit_code = exit_code
        @command = command
      end

      # Check if command was successful
      def success?
        @success
      end

      # Check if command failed
      def failure?
        !@success
      end

      # Get combined output (stdout + stderr)
      def output
        [stdout, stderr].reject(&:empty?).join("\n")
      end

      # Get error message if failed
      def error_message
        return nil if success?

        stderr.empty? ? stdout : stderr
      end

      # String representation
      def to_s
        status = success? ? 'SUCCESS' : 'FAILURE'
        "#{status} (exit: #{exit_code})"
      end

      def inspect
        "#<#{self.class.name} success=#{success?} exit_code=#{exit_code}>"
      end
    end
  end
end
