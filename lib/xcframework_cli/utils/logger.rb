# frozen_string_literal: true

require 'colorize'

module XCFrameworkCLI
  module Utils
    # Colored logger for CLI output
    class Logger
      LEVELS = {
        debug: :light_black,
        info: :white,
        success: :green,
        warning: :yellow,
        error: :red
      }.freeze

      class << self
        attr_accessor :verbose, :quiet

        def debug(message)
          return unless verbose

          log(:debug, "🔍 #{message}")
        end

        def info(message)
          return if quiet

          log(:info, "ℹ️  #{message}")
        end

        def success(message)
          return if quiet

          log(:success, "✅ #{message}")
        end

        def warning(message)
          return if quiet

          log(:warning, "⚠️  #{message}")
        end

        def error(message)
          log(:error, "❌ #{message}")
        end

        def section(title)
          return if quiet

          puts
          puts "═" * 60
          puts "  #{title}".colorize(:cyan).bold
          puts "═" * 60
          puts
        end

        def step(message)
          return if quiet

          puts "→ #{message}".colorize(:blue)
        end

        def result(message, success: true)
          return if quiet

          if success
            puts "  ✓ #{message}".colorize(:green)
          else
            puts "  ✗ #{message}".colorize(:red)
          end
        end

        def blank_line
          puts unless quiet
        end

        private

        def log(level, message)
          color = LEVELS[level]
          puts message.colorize(color)
        end
      end

      # Default settings
      @verbose = false
      @quiet = false
    end
  end
end

