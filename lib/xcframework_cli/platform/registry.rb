# frozen_string_literal: true

require_relative 'base'
require_relative 'ios'
require_relative 'ios_simulator'

module XCFrameworkCLI
  module Platform
    # Registry for managing platform instances
    # Provides factory methods for creating platform objects
    class Registry
      # Map of platform identifiers to platform classes
      PLATFORMS = {
        'ios' => IOS,
        'ios-simulator' => IOSSimulator
      }.freeze

      class << self
        # Create a platform instance by identifier
        # @param identifier [String] Platform identifier (e.g., "ios", "ios-simulator")
        # @return [Base] Platform instance
        # @raise [UnsupportedPlatformError] if platform is not supported
        def create(identifier)
          platform_class = PLATFORMS[identifier.to_s]

          raise UnsupportedPlatformError, "Unsupported platform: #{identifier}" unless platform_class

          platform_class.new
        end

        # Check if a platform identifier is valid
        # @param identifier [String] Platform identifier
        # @return [Boolean] true if platform is supported
        def valid?(identifier)
          PLATFORMS.key?(identifier.to_s)
        end

        # Get all supported platform identifiers
        # @return [Array<String>] List of platform identifiers
        def all_platforms
          PLATFORMS.keys
        end

        # Get all platform instances
        # @return [Array<Base>] List of platform instances
        def all_instances
          PLATFORMS.values.map(&:new)
        end

        # Get platform class by identifier
        # @param identifier [String] Platform identifier
        # @return [Class, nil] Platform class or nil if not found
        def platform_class(identifier)
          PLATFORMS[identifier.to_s]
        end

        # Get platform information
        # @return [Hash] Platform information with details
        def platform_info
          PLATFORMS.transform_values do |platform_class|
            {
              name: platform_class.platform_name,
              sdk: platform_class.sdk_name,
              destination: platform_class.destination,
              architectures: platform_class.valid_architectures,
              deployment_target: platform_class.default_deployment_target
            }
          end
        end

        # Validate a list of platform identifiers
        # @param identifiers [Array<String>] Platform identifiers to validate
        # @return [Array<String>] List of invalid platform identifiers
        def validate_platforms(identifiers)
          identifiers.reject { |id| valid?(id) }
        end

        # Create multiple platform instances
        # @param identifiers [Array<String>] Platform identifiers
        # @return [Array<Base>] List of platform instances
        # @raise [UnsupportedPlatformError] if any platform is not supported
        def create_all(identifiers)
          invalid = validate_platforms(identifiers)
          unless invalid.empty?
            raise UnsupportedPlatformError,
                  "Unsupported platforms: #{invalid.join(', ')}. " \
                  "Valid platforms: #{all_platforms.join(', ')}"
          end

          identifiers.map { |id| create(id) }
        end
      end
    end
  end
end
