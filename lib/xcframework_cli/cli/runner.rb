# frozen_string_literal: true

require 'thor'
require_relative 'commands/build'
require_relative '../version'
require_relative '../utils/logger'

module XCFrameworkCLI
  module CLI
    # Main CLI runner that registers Thor commands
    class Runner < Thor
      class << self
        def exit_on_failure?
          true
        end
      end

      # Global options
      class_option :verbose,
                   type: :boolean,
                   aliases: '-v',
                   desc: 'Enable verbose output',
                   default: false

      class_option :quiet,
                   type: :boolean,
                   aliases: '-q',
                   desc: 'Suppress output',
                   default: false

      desc 'build', 'Build XCFramework for iOS platforms'
      long_desc <<~DESC
        Build an XCFramework for iOS device and iOS Simulator platforms.

        You can provide configuration via command-line options or a configuration file.

        EXAMPLES:

        Build using command-line options:

          $ xcframework-cli build \\
              --project MySDK.xcodeproj \\
              --scheme MySDK \\
              --framework-name MySDK \\
              --output build \\
              --platforms ios ios-simulator

        Build using a configuration file:

          $ xcframework-cli build --config .xcframework.yml

        OPTIONS:
      DESC
      method_option :config,
                    type: :string,
                    aliases: '-c',
                    desc: 'Path to configuration file (.yml or .json)'

      method_option :project,
                    type: :string,
                    aliases: '-p',
                    desc: 'Path to Xcode project (.xcodeproj or .xcworkspace)'

      method_option :scheme,
                    type: :string,
                    aliases: '-s',
                    desc: 'Xcode scheme name'

      method_option :framework_name,
                    type: :string,
                    aliases: '-f',
                    desc: 'Framework name (without .framework extension)'

      method_option :output,
                    type: :string,
                    aliases: '-o',
                    desc: 'Output directory for build artifacts',
                    default: 'build'

      method_option :platforms,
                    type: :array,
                    desc: 'Platforms to build (ios, ios-simulator)',
                    default: %w[ios ios-simulator]

      method_option :clean,
                    type: :boolean,
                    desc: 'Clean build artifacts before building',
                    default: true

      method_option :debug_symbols,
                    type: :boolean,
                    desc: 'Include debug symbols (dSYM files)',
                    default: true

      def build
        # Execute the build command directly
        Commands::Build.execute(options)
      rescue XCFrameworkCLI::Error => e
        handle_error(e)
        exit(1)
      rescue StandardError => e
        handle_unexpected_error(e)
        exit(1)
      end

      desc 'version', 'Display version information'
      def version
        puts "XCFramework CLI v#{XCFrameworkCLI::VERSION}"
        puts 'A professional Ruby CLI tool for building XCFrameworks'
      end

      map %w[-v --version] => :version

      desc 'help [COMMAND]', 'Display help information'
      def help(command = nil)
        if command
          super
        else
          puts
          puts 'XCFramework CLI - Build XCFrameworks for Apple platforms'
          puts
          puts 'USAGE:'
          puts '  xcframework-cli COMMAND [OPTIONS]'
          puts
          puts 'COMMANDS:'
          puts '  build       Build XCFramework for iOS platforms'
          puts '  version     Display version information'
          puts '  help        Display this help message'
          puts
          puts 'GLOBAL OPTIONS:'
          puts '  -v, --verbose    Enable verbose output'
          puts '  -q, --quiet      Suppress output'
          puts
          puts 'Run "xcframework-cli help COMMAND" for more information on a command.'
          puts
        end
      end

      default_task :help

      private

      def handle_error(error)
        Utils::Logger.error(error.message)

        return unless error.respond_to?(:suggestions) && error.suggestions&.any?

        Utils::Logger.blank_line
        Utils::Logger.info('Suggestions:')
        error.suggestions.each do |suggestion|
          Utils::Logger.info("  • #{suggestion}")
        end
      end

      def handle_unexpected_error(error)
        Utils::Logger.error("Unexpected error: #{error.message}")
        warn error.backtrace.join("\n")
      end
    end
  end
end
