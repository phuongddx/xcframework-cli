# frozen_string_literal: true

module XCFrameworkCLI
  module Config
    # Default configuration values
    module Defaults
      # Default build settings
      BUILD_DEFAULTS = {
        output_dir: 'build',
        xcframework_output: '../SDKs',
        parallel_builds: false,
        clean_before_build: true
      }.freeze

      # Default deployment targets for each platform
      DEPLOYMENT_TARGETS = {
        'ios' => '14.0',
        'ios-simulator' => '14.0',
        'macos' => '11.0',
        'catalyst' => '14.0',
        'tvos' => '14.0',
        'tvos-simulator' => '14.0',
        'watchos' => '7.0',
        'watchos-simulator' => '7.0',
        'visionos' => '1.0',
        'visionos-simulator' => '1.0'
      }.freeze

      # Default architectures for each platform
      ARCHITECTURES = {
        'ios' => ['arm64'],
        'ios-simulator' => %w[arm64 x86_64],
        'macos' => %w[arm64 x86_64],
        'catalyst' => %w[arm64 x86_64],
        'tvos' => ['arm64'],
        'tvos-simulator' => %w[arm64 x86_64],
        'watchos' => %w[arm64 arm64_32],
        'watchos-simulator' => %w[arm64 x86_64],
        'visionos' => ['arm64'],
        'visionos-simulator' => ['arm64']
      }.freeze

      # Default publishing settings
      PUBLISHING_DEFAULTS = {
        git_branch: 'main',
        package_scope: 'com.aavn'
      }.freeze

      class << self
        # Merge defaults with user configuration
        def apply(config)
          config = deep_symbolize_keys(config)

          # Apply build defaults
          config[:build] ||= {}
          config[:build] = BUILD_DEFAULTS.merge(config[:build])

          # Apply framework defaults
          config[:frameworks]&.each do |framework|
            apply_framework_defaults(framework)
          end

          # Apply publishing defaults
          config[:publishing] = PUBLISHING_DEFAULTS.merge(config[:publishing]) if config[:publishing]

          config
        end

        private

        def apply_framework_defaults(framework)
          # Apply default architectures if not specified
          framework[:architectures] ||= {}
          framework[:platforms]&.each do |platform|
            framework[:architectures][platform.to_sym] ||= ARCHITECTURES[platform]
          end

          # Apply default deployment targets if not specified
          framework[:deployment_targets] ||= {}
          framework[:platforms]&.each do |platform|
            framework[:deployment_targets][platform.to_sym] ||= DEPLOYMENT_TARGETS[platform]
          end
        end

        def deep_symbolize_keys(obj)
          case obj
          when Hash
            obj.each_with_object({}) do |(key, value), result|
              result[key.to_sym] = deep_symbolize_keys(value)
            end
          when Array
            obj.map { |item| deep_symbolize_keys(item) }
          else
            obj
          end
        end
      end
    end
  end
end
