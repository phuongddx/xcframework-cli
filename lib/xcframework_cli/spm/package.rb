# frozen_string_literal: true

require 'json'

module XCFrameworkCLI
  module SPM
    # Package descriptor for Swift Package Manager
    # Parses Package.swift and provides access to targets, platforms, dependencies
    class Package
      attr_reader :package_dir, :name, :platforms, :targets, :products, :dependencies

      # Initialize package descriptor
      #
      # @param package_dir [String] Path to directory containing Package.swift
      def initialize(package_dir = '.')
        @package_dir = File.expand_path(package_dir)
        validate_package!
        load_package_manifest
      end

      # Get target by name
      #
      # @param name [String] Target name
      # @return [Target, nil] Target instance or nil if not found
      def target(name)
        targets.find { |t| t.name == name }
      end

      # Get library targets only
      #
      # @return [Array<Target>] Library targets
      def library_targets
        targets.select(&:library?)
      end

      # Get executable targets only
      #
      # @return [Array<Target>] Executable targets
      def executable_targets
        targets.select(&:executable?)
      end

      # Get binary targets only
      #
      # @return [Array<Target>] Binary targets
      def binary_targets
        targets.select(&:binary?)
      end

      # Get platform version
      #
      # @param platform [Symbol, String] Platform name (:ios, :macos, etc.)
      # @return [String, nil] Platform version or nil if not specified
      def platform_version(platform)
        platforms[platform.to_s]
      end

      # Reload package manifest
      #
      # @return [void]
      def reload!
        load_package_manifest
      end

      # Package.swift file path
      #
      # @return [String] Path to Package.swift
      def package_swift_path
        File.join(package_dir, 'Package.swift')
      end

      # Check if package has target
      #
      # @param name [String] Target name
      # @return [Boolean] true if target exists
      def has_target?(name)
        targets.any? { |t| t.name == name }
      end

      private

      # Validate package directory
      #
      # @raise [ValidationError] if Package.swift not found
      def validate_package!
        return if File.exist?(package_swift_path)

        raise ValidationError.new(
          "No Package.swift found in #{package_dir}",
          suggestions: [
            'Ensure you are in a Swift Package directory',
            'Check that Package.swift exists'
          ]
        )
      end

      # Load package manifest using swift package dump-package
      #
      # @return [void]
      def load_package_manifest
        Utils::Logger.debug("Loading package manifest from #{package_dir}")

        require 'open3'
        cmd = ['swift', 'package', 'dump-package', '--package-path', package_dir]
        stdout, stderr, status = Open3.capture3(*cmd)

        unless status.success?
          raise Error, "Failed to load Package.swift: #{stderr}"
        end

        parse_manifest(stdout.strip)
      rescue JSON::ParserError => e
        raise Error, "Failed to parse Package.swift: #{e.message}"
      end

      # Parse package manifest JSON
      #
      # @param json_string [String] JSON output from swift package dump-package
      # @return [void]
      def parse_manifest(json_string)
        data = JSON.parse(json_string)

        @name = data['name']
        @platforms = parse_platforms(data['platforms'] || [])
        @targets = parse_targets(data['targets'] || [])
        @products = parse_products(data['products'] || [])
        @dependencies = parse_dependencies(data['dependencies'] || [])
      end

      # Parse platforms from manifest
      #
      # @param platforms_data [Array<Hash>] Platforms array from manifest
      # @return [Hash] Platform name => version mapping
      def parse_platforms(platforms_data)
        result = {}
        platforms_data.each do |platform|
          name = platform['platformName']
          version = platform['version']
          result[name] = version
        end
        result
      end

      # Parse targets from manifest
      #
      # @param targets_data [Array<Hash>] Targets array from manifest
      # @return [Array<Target>] Array of Target instances
      def parse_targets(targets_data)
        targets_data.map do |target_data|
          Target.new(
            name: target_data['name'],
            type: target_data['type'],
            path: target_data['path'],
            sources: target_data['sources'] || [],
            dependencies: target_data['dependencies'] || [],
            package: self
          )
        end
      end

      # Parse products from manifest
      #
      # @param products_data [Array<Hash>] Products array from manifest
      # @return [Array<Hash>] Array of product hashes
      def parse_products(products_data)
        products_data.map do |product|
          {
            name: product['name'],
            type: product['type'],
            targets: product['targets'] || []
          }
        end
      end

      # Parse dependencies from manifest
      #
      # @param dependencies_data [Array<Hash>] Dependencies array from manifest
      # @return [Array<Hash>] Array of dependency hashes
      def parse_dependencies(dependencies_data)
        dependencies_data.map do |dep|
          {
            name: dep['name'] || dep['identity'],
            url: dep['url'],
            requirement: dep['requirement']
          }
        end
      end

      # Target representation
      class Target
        attr_reader :name, :type, :path, :sources, :dependencies, :package

        # Target type constants
        TYPE_REGULAR = 'regular'
        TYPE_EXECUTABLE = 'executable'
        TYPE_TEST = 'test'
        TYPE_BINARY = 'binary'
        TYPE_PLUGIN = 'plugin'
        TYPE_MACRO = 'macro'

        # Initialize target
        #
        # @param name [String] Target name
        # @param type [String] Target type
        # @param path [String, nil] Target path
        # @param sources [Array<String>] Source files
        # @param dependencies [Array] Target dependencies
        # @param package [Package] Parent package
        def initialize(name:, type:, path: nil, sources: [], dependencies: [], package: nil)
          @name = name
          @type = type
          @path = path
          @sources = sources
          @dependencies = dependencies
          @package = package
        end

        # Check if target is a library
        #
        # @return [Boolean] true if library target
        def library?
          type == TYPE_REGULAR
        end

        # Check if target is executable
        #
        # @return [Boolean] true if executable target
        def executable?
          type == TYPE_EXECUTABLE
        end

        # Check if target is a test
        #
        # @return [Boolean] true if test target
        def test?
          type == TYPE_TEST
        end

        # Check if target is binary
        #
        # @return [Boolean] true if binary target
        def binary?
          type == TYPE_BINARY
        end

        # Check if target is a macro
        #
        # @return [Boolean] true if macro target
        def macro?
          type == TYPE_MACRO
        end

        # Check if target is a plugin
        #
        # @return [Boolean] true if plugin target
        def plugin?
          type == TYPE_PLUGIN
        end

        # Get module name (C99-compatible identifier)
        #
        # @return [String] Module name
        def module_name
          name.gsub(/[^a-zA-Z0-9_]/, '_')
        end

        # String representation
        #
        # @return [String] Target name
        def to_s
          name
        end
      end
    end
  end
end
