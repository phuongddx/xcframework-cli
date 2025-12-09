# frozen_string_literal: true

require 'thor'

module XCFrameworkCLI
  module CLI
    module Commands
      # CLI commands for Swift Package Manager (SPM) builds
      class SPM < Thor
        desc 'build [TARGET...]', 'Build XCFramework from Swift Package'
        long_desc <<~DESC
          Build XCFramework from a Swift Package.

          If no targets are specified, all library targets will be built.

          Examples:
            xckit spm build                     # Build all library targets
            xckit spm build MyLibrary           # Build specific target
            xckit spm build Lib1 Lib2          # Build multiple targets
            xckit spm build --config spm.yml    # Use config file
        DESC

        option :package_dir, type: :string, default: '.', desc: 'Path to Package.swift directory'
        option :platforms, type: :array, default: %w[ios ios-simulator],
                           desc: 'Target platforms (e.g., ios, macos)'
        option :output_dir, type: :string, default: './build', desc: 'Output directory'
        option :configuration, type: :string, default: 'release', desc: 'Build configuration (debug/release)'
        option :library_evolution, type: :boolean, default: true, desc: 'Enable library evolution'
        option :version, type: :string, desc: 'Platform version (e.g., 15.0)'
        option :config, type: :string, desc: 'Path to configuration file'
        option :verbose, type: :boolean, default: false, desc: 'Verbose output'
        option :quiet, type: :boolean, default: false, desc: 'Quiet mode'

        def build(*targets)
          configure_logger

          # Load configuration from file if specified
          if options[:config]
            config = load_config_file(options[:config])
            spm_config = config[:spm] || {}
            build_config = config[:build] || {}
          else
            spm_config = {}
            build_config = {}
          end

          # Merge CLI options with config file (CLI options take precedence, then config, then defaults)
          # Note: Thor options with defaults always have a value, so we check config first, then CLI defaults
          merged_config = {
            package_dir: spm_config[:package_dir] || options[:package_dir],
            targets: targets.any? ? targets : (spm_config[:targets] || []),
            platforms: spm_config[:platforms] || options[:platforms],
            output_dir: build_config[:output_dir] || options[:output_dir],
            configuration: build_config[:configuration] || options[:configuration],
            library_evolution: spm_config.key?(:library_evolution) ? spm_config[:library_evolution] : options[:library_evolution],
            version: spm_config[:version] || options[:version]
          }

          Utils::Logger.info("Building XCFramework from Swift Package...")
          Utils::Logger.info("Package: #{merged_config[:package_dir]}")
          Utils::Logger.info("Platforms: #{merged_config[:platforms].join(', ')}")

          # Execute build
          orchestrator = Builder::Orchestrator.new({})
          result = orchestrator.spm_build(merged_config)

          # Display results
          if result[:success]
            say "\n✓ Build successful!", :green
            say "\nCreated XCFrameworks:", :green
            result[:xcframework_paths].each do |path|
              say "  • #{path}", :green
            end

            exit 0
          else
            say "\n✗ Build failed!", :red
            say "\nErrors:", :red
            result[:errors].each do |error|
              say "  • #{error}", :red
            end

            exit 1
          end
        rescue StandardError => e
          say "\n✗ Error: #{e.message}", :red
          say e.backtrace.join("\n"), :red if options[:verbose]
          exit 1
        end

        private

        # Configure logger based on options
        def configure_logger
          XCFrameworkCLI.configure_logger(
            verbose: options[:verbose],
            quiet: options[:quiet]
          )
        end

        # Load configuration from file
        #
        # @param path [String] Path to config file
        # @return [Hash] Configuration hash
        def load_config_file(path)
          unless File.exist?(path)
            say "Configuration file not found: #{path}", :red
            exit 1
          end

          config = XCFrameworkCLI.load_config(path: path)

          unless config[:spm]
            say "Configuration file must contain 'spm' section", :red
            exit 1
          end

          config
        rescue StandardError => e
          say "Failed to load configuration: #{e.message}", :red
          exit 1
        end
      end
    end
  end
end
