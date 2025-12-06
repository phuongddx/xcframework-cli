# frozen_string_literal: true

require 'thor'
require_relative '../../config/loader'
require_relative '../../builder/orchestrator'
require_relative '../../utils/logger'
require_relative '../../errors'

module XCFrameworkCLI
  module CLI
    module Commands
      # Thor command for building XCFrameworks
      # rubocop:disable Metrics/ClassLength
      class Build < Thor::Group
        include Thor::Actions

        # Command-line options
        class_option :config,
                     type: :string,
                     aliases: '-c',
                     desc: 'Path to configuration file (.yml or .json)'

        class_option :project,
                     type: :string,
                     aliases: '-p',
                     desc: 'Path to Xcode project (.xcodeproj or .xcworkspace)'

        class_option :scheme,
                     type: :string,
                     aliases: '-s',
                     desc: 'Xcode scheme name'

        class_option :framework_name,
                     type: :string,
                     aliases: '-f',
                     desc: 'Framework name (without .framework extension)'

        class_option :output,
                     type: :string,
                     aliases: '-o',
                     desc: 'Output directory for build artifacts',
                     default: 'build'

        class_option :platforms,
                     type: :array,
                     desc: 'Platforms to build (ios, ios-simulator)',
                     default: %w[ios ios-simulator]

        class_option :clean,
                     type: :boolean,
                     desc: 'Clean build artifacts before building',
                     default: true

        class_option :debug_symbols,
                     type: :boolean,
                     desc: 'Include debug symbols (dSYM files)',
                     default: true

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

        def self.banner
          'xcframework-cli build [OPTIONS]'
        end

        def execute
          setup_logger
          config = load_configuration
          validate_configuration(config)
          run_build(config)
        rescue XCFrameworkCLI::Error => e
          handle_error(e)
          exit(1)
        rescue StandardError => e
          handle_unexpected_error(e)
          exit(1)
        end

        private

        def setup_logger
          Utils::Logger.verbose = options[:verbose]
          Utils::Logger.quiet = options[:quiet]
        end

        def load_configuration
          if options[:config]
            load_from_config_file
          else
            load_from_command_line
          end
        end

        # rubocop:disable Metrics/AbcSize
        def load_from_config_file
          Utils::Logger.debug("Loading configuration from: #{options[:config]}")
          config = Config::Loader.load(path: options[:config])

          # Extract first framework configuration
          framework = config[:frameworks]&.first
          raise ConfigError, 'No frameworks defined in configuration file' unless framework

          {
            project_path: config[:project][:xcode_project],
            scheme: framework[:scheme],
            framework_name: framework[:name],
            output_dir: config[:build][:output_dir] || options[:output],
            platforms: framework[:platforms] || options[:platforms],
            clean: config[:build][:clean_before_build].nil? ? options[:clean] : config[:build][:clean_before_build],
            include_debug_symbols: options[:debug_symbols]
          }
        end
        # rubocop:enable Metrics/AbcSize

        def load_from_command_line
          Utils::Logger.debug('Loading configuration from command-line arguments')

          {
            project_path: options[:project],
            scheme: options[:scheme],
            framework_name: options[:framework_name],
            output_dir: options[:output],
            platforms: options[:platforms],
            clean: options[:clean],
            include_debug_symbols: options[:debug_symbols]
          }
        end

        def validate_configuration(config)
          missing = []
          missing << '--project' unless config[:project_path]
          missing << '--scheme' unless config[:scheme]
          missing << '--framework-name' unless config[:framework_name]

          return if missing.empty?

          raise ValidationError.new(
            "Missing required arguments: #{missing.join(', ')}",
            suggestions: [
              'Provide all required arguments via command-line options',
              'Or use --config to load from a configuration file',
              'Run xcframework-cli help build for more information'
            ]
          )
        end

        def run_build(config)
          Utils::Logger.section('Building XCFramework')
          Utils::Logger.info("Project: #{config[:project_path]}")
          Utils::Logger.info("Scheme: #{config[:scheme]}")
          Utils::Logger.info("Framework: #{config[:framework_name]}")
          Utils::Logger.info("Platforms: #{config[:platforms].join(', ')}")
          Utils::Logger.blank_line

          orchestrator = Builder::Orchestrator.new(config)
          result = orchestrator.build

          display_result(result)
        end

        def display_result(result)
          Utils::Logger.blank_line

          if result[:success]
            Utils::Logger.success('Build completed successfully!')
            Utils::Logger.info("XCFramework: #{result[:xcframework_path]}")
            Utils::Logger.blank_line
            Utils::Logger.info('Archives created:')
            result[:archives].each do |archive|
              Utils::Logger.result("#{archive[:platform]}: #{archive[:archive_path]}", success: true)
            end
          else
            Utils::Logger.error('Build failed!')
            Utils::Logger.blank_line
            Utils::Logger.error('Errors:')
            result[:errors].each do |error|
              Utils::Logger.result(error, success: false)
            end
            exit(1)
          end
        end

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
          Utils::Logger.debug(error.backtrace.join("\n")) if Utils::Logger.verbose
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
