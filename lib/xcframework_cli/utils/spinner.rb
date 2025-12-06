# frozen_string_literal: true

require 'tty-spinner'

module XCFrameworkCLI
  module Utils
    # Wrapper for TTY::Spinner with consistent styling
    class Spinner
      def self.spin(message, &block)
        return yield if Logger.quiet

        spinner = TTY::Spinner.new("[:spinner] #{message}...", format: :dots)
        spinner.auto_spin

        result = nil
        error = nil

        begin
          result = yield
          spinner.success('Done!')
        rescue StandardError => e
          error = e
          spinner.error('Failed!')
        end

        raise error if error

        result
      end

      def self.multi(message)
        return yield if Logger.quiet

        multi_spinner = TTY::Spinner::Multi.new("[:spinner] #{message}")
        yield multi_spinner
        multi_spinner.auto_spin
      end
    end
  end
end

