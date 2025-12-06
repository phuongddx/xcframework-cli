# frozen_string_literal: true

require_relative 'base'

module XCFrameworkCLI
  module Platform
    # iOS device platform
    # Builds for physical iOS devices (iPhone, iPad)
    class IOS < Base
      class << self
        def platform_name
          'iOS'
        end

        def platform_identifier
          'ios'
        end

        def sdk_name
          'iphoneos'
        end

        def destination
          'generic/platform=iOS'
        end

        def valid_architectures
          ['arm64']
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
