# frozen_string_literal: true

module XCFrameworkCLI
  module Swift
    # Swift build wrapper for executing swift build commands
    # Handles SPM compilation with proper SDK targeting and library evolution
    class Builder
      attr_reader :package_dir, :target, :sdk, :configuration, :library_evolution

      # Initialize builder
      #
      # @param package_dir [String] Path to Package.swift directory
      # @param target [String] Target name to build
      # @param sdk [SDK] SDK instance for compilation
      # @param configuration [String] Build configuration ('debug' or 'release')
      # @param library_evolution [Boolean] Enable library evolution
      def initialize(package_dir:, target:, sdk:, configuration: 'release', library_evolution: true)
        @package_dir = package_dir
        @target = target
        @sdk = sdk
        @configuration = configuration.downcase
        @library_evolution = library_evolution

        validate_configuration!
      end

      # Execute swift build
      #
      # @return [Hash] Build result with :success, :build_dir, :products_dir, :error
      def build
        Utils::Logger.info("Building #{target} for #{sdk.triple(with_version: true)} (#{configuration})...")

        cmd = build_command
        Utils::Logger.debug("Executing: #{cmd.join(' ')}")

        result = execute_command(cmd)

        if result[:status].success?
          # Swift build creates directories using triple WITHOUT version
          # even though the command uses triple WITH version
          build_dir = File.join(package_dir, '.build', sdk.triple, configuration)
          {
            success: true,
            build_dir: build_dir,
            products_dir: build_dir,
            triple: sdk.triple,
            output: result[:output]
          }
        else
          Utils::Logger.error("Swift build failed for #{target}")
          {
            success: false,
            build_dir: nil,
            products_dir: nil,
            error: result[:output]
          }
        end
      rescue StandardError => e
        Utils::Logger.error("Build execution failed: #{e.message}")
        {
          success: false,
          build_dir: nil,
          products_dir: nil,
          error: e.message
        }
      end

      # Get build products directory for this SDK/config
      #
      # @return [String] Path to build products directory
      def products_dir
        File.join(package_dir, '.build', sdk.triple, configuration)
      end

      # Get object files directory for target
      #
      # @param module_name [String] Module name (defaults to target)
      # @return [String] Path to .build directory with .o files
      def object_files_dir(module_name: nil)
        module_name ||= target
        c99_module_name = module_name.gsub(/[^a-zA-Z0-9_]/, '_')
        File.join(products_dir, "#{c99_module_name}.build")
      end

      private

      # Build swift build command
      #
      # @return [Array<String>] Command array
      def build_command
        cmd = ['swift', 'build']
        cmd << '--package-path' << package_dir
        cmd << '--target' << target
        cmd << '--configuration' << configuration
        cmd << '--triple' << sdk.triple(with_version: true)
        cmd << '--sdk' << sdk.sdk_path

        # Add Swift compiler arguments
        sdk.swiftc_args.each do |arg|
          cmd << '-Xswiftc' << arg
        end

        # Library evolution support
        if library_evolution
          cmd << '-Xswiftc' << '-enable-library-evolution'
          cmd << '-Xswiftc' << '-emit-module-interface'
          # Workaround for Swift interface verification issues
          # https://github.com/swiftlang/swift/issues/64669#issuecomment-1535335601
          cmd << '-Xswiftc' << '-no-verify-emitted-module-interface'
        end

        cmd
      end

      # Execute command and return output
      #
      # @param cmd [Array<String>] Command to execute
      # @return [Hash] Hash with :output and :status
      def execute_command(cmd)
        require 'open3'
        stdout, stderr, status = Open3.capture3(*cmd)
        output = stdout + stderr

        { output: output, status: status }
      end

      # Validate configuration
      #
      # @raise [ValidationError] if configuration is invalid
      def validate_configuration!
        unless %w[debug release].include?(configuration)
          raise ValidationError.new(
            "Invalid configuration: #{configuration}",
            suggestions: ["Use 'debug' or 'release'"]
          )
        end

        unless File.exist?(File.join(package_dir, 'Package.swift'))
          raise ValidationError.new(
            "No Package.swift found in #{package_dir}",
            suggestions: ["Ensure you're in a Swift Package directory"]
          )
        end
      end

      class << self
        # Execute swift build for multiple SDKs
        #
        # @param package_dir [String] Package directory
        # @param target [String] Target name
        # @param sdks [Array<SDK>] Array of SDKs
        # @param options [Hash] Build options
        # @return [Array<Hash>] Array of build results
        def build_for_sdks(package_dir:, target:, sdks:, **options)
          results = []

          sdks.each do |sdk|
            builder = new(
              package_dir: package_dir,
              target: target,
              sdk: sdk,
              **options
            )

            result = builder.build
            result[:sdk] = sdk
            results << result
          end

          results
        end

        # Get available platforms from Package.swift
        #
        # @param package_dir [String] Package directory
        # @return [Hash] Platform versions
        def package_platforms(package_dir)
          require 'open3'
          cmd = ['swift', 'package', 'dump-package', '--package-path', package_dir]
          stdout, _stderr, status = Open3.capture3(*cmd)

          if status.success?
            require 'json'
            package_data = JSON.parse(stdout)
            platforms = {}

            if package_data['platforms']
              package_data['platforms'].each do |platform|
                platform_name = platform['platformName']
                version = platform['version']
                platforms[platform_name] = version
              end
            end

            platforms
          else
            {}
          end
        rescue StandardError => e
          Utils::Logger.debug("Failed to parse Package.swift platforms: #{e.message}")
          {}
        end
      end
    end
  end
end
