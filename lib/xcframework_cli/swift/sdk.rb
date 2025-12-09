# frozen_string_literal: true

module XCFrameworkCLI
  module Swift
    # SDK abstraction for Swift compilation targets
    # Handles platform-specific compilation with triples, SDK paths, and compiler flags
    class SDK
      attr_reader :name, :architecture, :vendor, :platform
      attr_accessor :version

      # Mapping of SDK names to platform identifiers
      SDK_NAME_TO_PLATFORM = {
        iphonesimulator: :ios,
        iphoneos: :ios,
        macos: :macos,
        watchos: :watchos,
        watchsimulator: :watchos,
        appletvos: :tvos,
        appletvsimulator: :tvos,
        xros: :visionos,
        xrsimulator: :visionos
      }.freeze

      # Default architectures for each platform
      DEFAULT_ARCHITECTURES = {
        iphoneos: ['arm64'],
        iphonesimulator: %w[arm64 x86_64],
        macos: %w[arm64 x86_64],
        watchos: %w[arm64_32 armv7k],
        watchsimulator: %w[arm64 x86_64],
        appletvos: ['arm64'],
        appletvsimulator: %w[arm64 x86_64],
        xros: ['arm64'],
        xrsimulator: ['arm64']
      }.freeze

      # Initialize SDK
      #
      # @param name [Symbol, String] SDK name (e.g., :iphoneos, :iphonesimulator)
      # @param architecture [String] Target architecture (default: 'arm64')
      # @param version [String, nil] Platform version (e.g., '15.0')
      def initialize(name, architecture: 'arm64', version: nil)
        @name = name.to_sym
        @architecture = architecture
        @vendor = 'apple'
        @platform = SDK_NAME_TO_PLATFORM.fetch(@name, @name)
        @version = version

        validate_sdk_name!
      end

      # Generate triple string for Swift compilation
      #
      # @param with_vendor [Boolean] Include vendor in triple
      # @param with_version [Boolean] Include version in triple
      # @return [String] Triple string (e.g., "arm64-apple-ios15.0-simulator")
      def triple(with_vendor: true, with_version: false)
        components = [architecture]
        components << vendor if with_vendor

        platform_string = if with_version && version
                            "#{platform}#{version}"
                          else
                            platform.to_s
                          end
        components << platform_string
        components << 'simulator' if simulator?

        components.join('-')
      end

      # Get SDK name for xcrun/xcodebuild
      #
      # @return [Symbol] SDK name
      def sdk_name
        name == :macos ? :macosx : name
      end

      # Get SDK path using xcrun
      #
      # @return [String] Full path to SDK
      def sdk_path
        @sdk_path ||= begin
          require 'open3'
          cmd = ['xcrun', '--sdk', sdk_name.to_s, '--show-sdk-path']
          stdout, stderr, status = Open3.capture3(*cmd)

          if status.success?
            stdout.strip
          else
            raise Error, "Failed to get SDK path for #{sdk_name}: #{stderr}"
          end
        end
      end

      # Get platform developer path
      #
      # @return [String] Platform developer path
      def sdk_platform_developer_path
        @sdk_platform_developer_path ||= File.expand_path(File.join(sdk_path, '..', '..'))
      end

      # Get Swift compiler arguments for this SDK
      #
      # @return [Array<String>] Compiler arguments
      def swiftc_args
        developer_library_frameworks_path = File.join(sdk_platform_developer_path, 'Library', 'Frameworks')
        developer_usr_lib_path = File.join(sdk_platform_developer_path, 'usr', 'lib')

        args = [
          "-F#{developer_library_frameworks_path}",
          "-I#{developer_usr_lib_path}"
        ]
        args
      end

      # Check if this is a simulator SDK
      #
      # @return [Boolean] true if simulator
      def simulator?
        name.to_s.end_with?('simulator')
      end

      # String representation
      #
      # @return [String] SDK name as string
      def to_s
        name.to_s
      end

      # Create SDKs for a platform identifier
      #
      # @param platform_identifier [String] Platform identifier (e.g., 'ios', 'ios-simulator')
      # @param version [String, nil] Platform version
      # @return [Array<SDK>] Array of SDK instances
      def self.sdks_for_platform(platform_identifier, version: nil)
        case platform_identifier
        when 'ios'
          [new(:iphoneos, architecture: 'arm64', version: version)]
        when 'ios-simulator'
          [
            new(:iphonesimulator, architecture: 'arm64', version: version),
            new(:iphonesimulator, architecture: 'x86_64', version: version)
          ]
        when 'macos'
          [
            new(:macos, architecture: 'arm64', version: version),
            new(:macos, architecture: 'x86_64', version: version)
          ]
        when 'tvos'
          [new(:appletvos, architecture: 'arm64', version: version)]
        when 'tvos-simulator'
          [
            new(:appletvsimulator, architecture: 'arm64', version: version),
            new(:appletvsimulator, architecture: 'x86_64', version: version)
          ]
        when 'watchos'
          [
            new(:watchos, architecture: 'arm64_32', version: version),
            new(:watchos, architecture: 'armv7k', version: version)
          ]
        when 'watchos-simulator'
          [
            new(:watchsimulator, architecture: 'arm64', version: version),
            new(:watchsimulator, architecture: 'x86_64', version: version)
          ]
        when 'visionos'
          [new(:xros, architecture: 'arm64', version: version)]
        when 'visionos-simulator'
          [new(:xrsimulator, architecture: 'arm64', version: version)]
        when 'catalyst'
          [
            new(:macos, architecture: 'arm64', version: version),
            new(:macos, architecture: 'x86_64', version: version)
          ]
        else
          raise ValidationError.new(
            "Unknown platform identifier: #{platform_identifier}",
            suggestions: [
              'Use one of: ios, ios-simulator, macos, tvos, tvos-simulator, watchos, watchos-simulator, visionos, visionos-simulator, catalyst'
            ]
          )
        end
      end

      private

      # Validate SDK name
      #
      # @raise [ValidationError] if SDK name is invalid
      def validate_sdk_name!
        return if SDK_NAME_TO_PLATFORM.key?(name)

        raise ValidationError.new(
          "Unknown SDK: #{name}",
          suggestions: [
            "Valid SDKs: #{SDK_NAME_TO_PLATFORM.keys.join(', ')}"
          ]
        )
      end
    end
  end
end
