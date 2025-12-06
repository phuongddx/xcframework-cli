# frozen_string_literal: true

require 'thor'
require 'pathname'
require_relative '../../config/loader'
require_relative '../../builder/orchestrator'
require_relative '../../utils/logger'
require_relative '../../errors'

module XCFrameworkCLI
  module CLI
    module Commands
      # Command for building XCFrameworks
      module Build
        class << self
          def execute(options)
            # Load configuration first to get verbose setting
            config = load_configuration(options)
            # Setup logger with config settings (CLI options override)
            setup_logger(options, config[:_raw_config])
            validate_configuration(config)
            run_build(config)
          rescue XCFrameworkCLI::Error => e
            handle_error(e)
            exit(1)
          rescue StandardError => e
            warn "Error: #{e.message}"
            warn e.backtrace.join("\n")
            exit(1)
          end

          private

          def setup_logger(options, config = nil)
            # CLI options override config file settings
            verbose = options[:verbose] || (config && config[:build]&.[](:verbose)) || false
            quiet = options[:quiet] || false

            Utils::Logger.verbose = verbose
            Utils::Logger.quiet = quiet
          end

          def load_configuration(options)
            if options[:config]
              load_from_config_file(options)
            else
              load_from_command_line(options)
            end
          end

          # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
          def load_from_config_file(options)
            Utils::Logger.debug("Loading configuration from: #{options[:config]}")
            config = Config::Loader.load(path: options[:config])

            # Extract first framework configuration
            framework = config[:frameworks]&.first
            raise ConfigError, 'No frameworks defined in configuration file' unless framework

            # Resolve paths relative to config file directory
            config_dir = File.dirname(File.expand_path(options[:config]))

            # Resolve project path
            project_path = config[:project][:xcode_project]
            project_path = File.join(config_dir, project_path) unless Pathname.new(project_path).absolute?

            # Use --output if provided, otherwise use config's output_dir (resolved relative to config file)
            output_dir = if options[:output] && options[:output] != 'build'
                           options[:output]
                         else
                           config_output = config[:build][:output_dir] || 'build'
                           Pathname.new(config_output).absolute? ? config_output : File.join(config_dir, config_output)
                         end

            {
              project_path: project_path,
              scheme: framework[:scheme],
              framework_name: framework[:name],
              output_dir: output_dir,
              platforms: framework[:platforms] || options[:platforms],
              clean: config[:build][:clean_before_build].nil? ? options[:clean] : config[:build][:clean_before_build],
              include_debug_symbols: options[:debug_symbols],
              use_formatter: config[:build][:use_formatter],
              _raw_config: config
            }
          end
          # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

          def load_from_command_line(options)
            Utils::Logger.debug('Loading configuration from command-line arguments')

            {
              project_path: options[:project],
              scheme: options[:scheme],
              framework_name: options[:framework_name],
              output_dir: options[:output],
              platforms: options[:platforms],
              clean: options[:clean],
              include_debug_symbols: options[:debug_symbols],
              use_formatter: true # Default to true for command-line mode
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

          # rubocop:disable Metrics/AbcSize
          def display_result(result)
            Utils::Logger.blank_line

            if result[:success]
              Utils::Logger.success('Build completed successfully!')
              Utils::Logger.info("XCFramework: #{result[:xcframework_path]}")
              Utils::Logger.blank_line
              Utils::Logger.info('Archives created:')
              result[:archives].each do |archive|
                Utils::Logger.result("#{archive[:platform]}: #{archive[:platform]} - #{archive[:archive_path]}",
                                     success: true)
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
          # rubocop:enable Metrics/AbcSize

          def handle_error(error)
            Utils::Logger.error(error.message)

            return unless error.respond_to?(:suggestions) && error.suggestions&.any?

            Utils::Logger.blank_line
            Utils::Logger.info('Suggestions:')
            error.suggestions.each do |suggestion|
              Utils::Logger.info("  • #{suggestion}")
            end
          end
        end
      end
    end
  end
end
