# frozen_string_literal: true

require 'yaml'
require 'json'
require_relative 'schema'
require_relative 'defaults'
require_relative '../errors'

module XCFrameworkCLI
  module Config
    # Configuration file loader with validation
    class Loader
      CONFIG_FILES = [
        '.xcframework.yml',
        '.xcframework.yaml',
        'xcframework.yml',
        'xcframework.yaml',
        '.xcframework.json',
        'xcframework.json'
      ].freeze

      class << self
        # Load configuration from file or auto-detect
        def load(path: nil)
          config_path = path || find_config_file
          unless config_path
            raise FileNotFoundError.new(
              'No configuration file found',
              suggestions: [
                "Run 'xckit init' to create a configuration file",
                'Create .xcframework.yml manually',
                'Specify config path with --config option'
              ]
            )
          end

          config = load_file(config_path)
          config = Defaults.apply(config)
          validate(config)

          config
        end

        # Find configuration file in current directory
        def find_config_file
          CONFIG_FILES.find { |file| File.exist?(file) }
        end

        # Load configuration from file
        def load_file(path)
          unless File.exist?(path)
            raise FileNotFoundError.new(
              "Configuration file not found: #{path}",
              suggestions: [
                'Check the file path',
                'Ensure the file exists',
                "Run 'xckit init' to create a new config"
              ]
            )
          end

          content = File.read(path)

          case File.extname(path)
          when '.yml', '.yaml'
            YAML.safe_load(content, symbolize_names: true, aliases: true)
          when '.json'
            JSON.parse(content, symbolize_names: true)
          else
            raise ConfigError.new(
              "Unsupported configuration file format: #{path}",
              suggestions: [
                'Use .yml, .yaml, or .json extension',
                'Check the file format'
              ]
            )
          end
        rescue Psych::SyntaxError => e
          raise ConfigError.new(
            "Invalid YAML syntax in #{path}: #{e.message}",
            suggestions: [
              'Check YAML syntax',
              'Use a YAML validator',
              'See examples in config/examples/'
            ]
          )
        rescue JSON::ParserError => e
          raise ConfigError.new(
            "Invalid JSON syntax in #{path}: #{e.message}",
            suggestions: [
              'Check JSON syntax',
              'Use a JSON validator',
              'See examples in config/examples/'
            ]
          )
        end

        # Validate configuration against schema
        def validate(config)
          result = Schema.new.call(config)

          return config if result.success?

          errors = format_errors(result.errors.to_h)
          raise ValidationError.new(
            "Configuration validation failed:\n#{errors}",
            suggestions: [
              'Check the configuration file syntax',
              'See REFACTORING_ANALYSIS_AND_PLAN.md for examples',
              'Run with --verbose for more details'
            ]
          )
        end

        private

        def format_errors(errors, prefix = '')
          errors.map do |key, value|
            if value.is_a?(Hash)
              format_errors(value, "#{prefix}#{key}.")
            elsif value.is_a?(Array)
              value.map { |v| "  • #{prefix}#{key}: #{v}" }.join("\n")
            else
              "  • #{prefix}#{key}: #{value}"
            end
          end.join("\n")
        end
      end
    end
  end
end
