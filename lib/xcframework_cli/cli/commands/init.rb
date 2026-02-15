# frozen_string_literal: true

module XCFrameworkCLI
  module CLI
    module Commands
      # Initialize new XCFramework configuration
      class Init
        class << self
          # Execute init command
          #
          # @param options [Hash] Command options
          # @return [void]
          def execute(options = {})
            configure_logger(options)

            Utils::Logger.info('Initializing XCFramework configuration...')
            Utils::Logger.blank_line

            # Check if config already exists
            if config_file_exists? && !force_overwrite?
              Utils::Logger.warning('Configuration file already exists.')
              Utils::Logger.info('Use --force to overwrite')
              exit 1
            end

            # Detect project type
            detection = Project::Detector.detect('.')

            case detection[:type]
            when :spm
              handle_spm_project(detection[:metadata], options)
            when :xcode
              handle_xcode_project(detection[:metadata], options)
            when :none
              handle_no_project
            end
          end

          private

          # Configure logger
          #
          # @param options [Hash] Command options
          def configure_logger(options)
            XCFrameworkCLI.configure_logger(
              verbose: options[:verbose] || false,
              quiet: options[:quiet] || false
            )
          end

          # Check if config file exists
          #
          # @return [Boolean] true if config file exists
          def config_file_exists?
            Config::Loader::CONFIG_FILES.any? { |file| File.exist?(file) }
          end

          # Ask user if they want to overwrite existing config
          #
          # @return [Boolean] true if user confirms overwrite
          def force_overwrite?
            print 'Overwrite existing configuration? (y/N): '
            response = $stdin.gets&.chomp&.downcase
            %w[y yes].include?(response)
          end

          # Handle Swift Package project
          #
          # @param metadata [Hash] Package metadata
          # @param options [Hash] Command options
          # rubocop:disable Metrics/AbcSize
          def handle_spm_project(metadata, options)
            Utils::Logger.success("Detected Swift Package: #{metadata[:package_name]}")

            if metadata[:targets].empty?
              Utils::Logger.error('No library targets found in Package.swift')
              exit 1
            end

            Utils::Logger.info("Found #{metadata[:targets].length} library target(s):")
            metadata[:targets].each do |target|
              Utils::Logger.info("  • #{target}")
            end
            Utils::Logger.blank_line

            # Show platform info
            unless metadata[:platforms].empty?
              Utils::Logger.info('Platform requirements:')
              metadata[:platforms].each do |platform, version|
                Utils::Logger.info("  • #{platform}: #{version}")
              end
              Utils::Logger.blank_line
            end

            # Generate config
            config = Config::Generator.spm_template(
              targets: metadata[:targets],
              platforms: metadata[:platforms]
            )

            # Write config file
            write_config_file(config, options[:format] || 'yml')

            Utils::Logger.blank_line
            Utils::Logger.success('Configuration created successfully!')
            Utils::Logger.info("Run 'xckit spm build' to build your XCFramework")
          end
          # rubocop:enable Metrics/AbcSize

          # Handle Xcode project
          #
          # @param metadata [Hash] Project metadata
          # @param options [Hash] Command options
          # rubocop:disable Metrics/AbcSize
          def handle_xcode_project(metadata, options)
            Utils::Logger.success("Detected Xcode project: #{metadata[:project_name]}")

            if metadata[:schemes].empty?
              Utils::Logger.error('No schemes found in project')
              Utils::Logger.info('Make sure your project has at least one scheme')
              exit 1
            end

            Utils::Logger.info("Found #{metadata[:schemes].length} scheme(s):")
            metadata[:schemes].each do |scheme|
              Utils::Logger.info("  • #{scheme}")
            end
            Utils::Logger.blank_line

            # Use first scheme as default
            scheme = metadata[:schemes].first
            framework_name = scheme

            Utils::Logger.info("Using scheme: #{scheme}")
            Utils::Logger.info("Framework name: #{framework_name}")
            Utils::Logger.blank_line

            # Generate config
            config = Config::Generator.xcode_template(
              project_path: metadata[:project_path],
              scheme: scheme,
              framework_name: framework_name
            )

            # Write config file
            write_config_file(config, options[:format] || 'yml')

            Utils::Logger.blank_line
            Utils::Logger.success('Configuration created successfully!')
            Utils::Logger.info("Run 'xckit build' to build your XCFramework")
          end
          # rubocop:enable Metrics/AbcSize

          # Handle no project found
          def handle_no_project
            Utils::Logger.error('No Package.swift or Xcode project found')
            Utils::Logger.blank_line
            Utils::Logger.info('To initialize a configuration, you need either:')
            Utils::Logger.info('  • A Swift Package (Package.swift)')
            Utils::Logger.info('  • An Xcode project (.xcodeproj or .xcworkspace)')
            exit 1
          end

          # Write config file
          #
          # @param config [Hash] Configuration data
          # @param format [String] Output format (yml or json)
          def write_config_file(config, format)
            generator = Config::Generator.new(config)

            filename = format == 'json' ? '.xcframework.json' : '.xcframework.yml'
            content = format == 'json' ? generator.to_json : generator.to_yaml

            File.write(filename, content)
            Utils::Logger.success("Created #{filename}")
          end
        end
      end
    end
  end
end
