# frozen_string_literal: true

require_relative 'base'

module XCFrameworkCLI
  module Platform
    # iOS Simulator platform
    # Builds for iOS Simulator (supports both Apple Silicon and Intel Macs)
    class IOSSimulator < Base
      class << self
        def platform_name
          'iOS Simulator'
        end

        def platform_identifier
          'ios-simulator'
        end

        def sdk_name
          'iphonesimulator'
        end

        def destination
          'generic/platform=iOS Simulator'
        end

        def valid_architectures
          %w[arm64 x86_64]
        end

        def default_deployment_target
          '14.0'
        end
      end

      def sdk_version_key
        'IPHONEOS_DEPLOYMENT_TARGET'
      end
    end
  end
end
