# frozen_string_literal: true

require 'English'
module XCFrameworkCLI
  module Platform
    # Base class for all platform implementations
    # Defines the interface that all platform classes must implement
    class Base
      attr_reader :name

      def initialize
        @name = self.class.platform_name
      end

      # Platform identification
      class << self
        # Human-readable platform name (e.g., "iOS", "iOS Simulator")
        def platform_name
          raise NotImplementedError, "#{self} must implement .platform_name"
        end

        # Platform identifier used in configuration (e.g., "ios", "ios-simulator")
        def platform_identifier
          raise NotImplementedError, "#{self} must implement .platform_identifier"
        end

        # SDK name for xcodebuild (e.g., "iphoneos", "iphonesimulator")
        def sdk_name
          raise NotImplementedError, "#{self} must implement .sdk_name"
        end

        # Destination string for xcodebuild (e.g., "generic/platform=iOS")
        def destination
          raise NotImplementedError, "#{self} must implement .destination"
        end

        # Valid architectures for this platform (e.g., ["arm64"])
        def valid_architectures
          raise NotImplementedError, "#{self} must implement .valid_architectures"
        end

        # Default deployment target (e.g., "14.0")
        def default_deployment_target
          raise NotImplementedError, "#{self} must implement .default_deployment_target"
        end
      end

      # Instance methods that delegate to class methods
      def platform_name
        self.class.platform_name
      end

      def platform_identifier
        self.class.platform_identifier
      end

      def sdk_name
        self.class.sdk_name
      end

      def destination
        self.class.destination
      end

      def valid_architectures
        self.class.valid_architectures
      end

      def default_deployment_target
        self.class.default_deployment_target
      end

      # Get SDK path using xcrun
      # Returns the full path to the SDK
      def sdk_path
        @sdk_path ||= resolve_sdk_path
      end

      # Validate if an architecture is supported by this platform
      def supports_architecture?(arch)
        valid_architectures.include?(arch.to_s)
      end

      # Validate multiple architectures
      def validate_architectures(architectures)
        invalid = architectures.reject { |arch| supports_architecture?(arch) }
        return true if invalid.empty?

        raise InvalidArchitectureError,
              "Invalid architectures for #{name}: #{invalid.join(', ')}. " \
              "Valid architectures: #{valid_architectures.join(', ')}"
      end

      # Build settings for xcodebuild
      def build_settings(architectures: nil, deployment_target: nil)
        archs = architectures || valid_architectures
        target = deployment_target || default_deployment_target

        validate_architectures(archs)

        {
          'ARCHS' => archs.join(' '),
          'ONLY_ACTIVE_ARCH' => 'NO',
          'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
          'SKIP_INSTALL' => 'NO',
          sdk_version_key => target
        }
      end

      # SDK version key for build settings (e.g., IPHONEOS_DEPLOYMENT_TARGET)
      def sdk_version_key
        raise NotImplementedError, "#{self.class} must implement #sdk_version_key"
      end

      # String representation
      def to_s
        "#{name} (#{sdk_name})"
      end

      def inspect
        "#<#{self.class.name} name=#{name} sdk=#{sdk_name} archs=#{valid_architectures.join(',')}>"
      end

      private

      # Resolve SDK path using xcrun
      def resolve_sdk_path
        cmd = "xcrun --sdk #{sdk_name} --show-sdk-path"
        output = execute_command(cmd)

        if output && !output.empty?
          output
        else
          raise PlatformError,
                "Failed to resolve SDK path for #{name}. " \
                "Make sure Xcode is installed and '#{sdk_name}' SDK is available."
        end
      end

      # Execute a shell command and return output if successful
      def execute_command(cmd)
        output = `#{cmd}`.strip
        $CHILD_STATUS.success? ? output : nil
      end
    end
  end
end
