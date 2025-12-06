# frozen_string_literal: true

require 'dry-validation'

module XCFrameworkCLI
  module Config
    # Configuration schema validation using dry-validation
    class Schema < Dry::Validation::Contract
      # Valid platform names
      VALID_PLATFORMS = %w[
        ios
        ios-simulator
        macos
        catalyst
        tvos
        tvos-simulator
        watchos
        watchos-simulator
        visionos
        visionos-simulator
      ].freeze

      # Valid architectures
      VALID_ARCHITECTURES = %w[
        arm64
        x86_64
        arm64_32
      ].freeze

      params do
        required(:project).hash do
          required(:name).filled(:string)
          required(:xcode_project).filled(:string)
        end

        required(:frameworks).array(:hash) do
          required(:name).filled(:string)
          required(:scheme).filled(:string)
          required(:platforms).array(:string)
          optional(:architectures).hash
          optional(:deployment_targets).hash
          optional(:resource_bundles).array(:string)
          optional(:resource_module).filled(:string)
          optional(:resource_accessor_template).filled(:string)
        end

        optional(:build).hash do
          optional(:output_dir).filled(:string)
          optional(:xcframework_output).filled(:string)
          optional(:parallel_builds).filled(:bool)
          optional(:clean_before_build).filled(:bool)
          optional(:verbose).filled(:bool)
          optional(:use_formatter).filled
        end

        optional(:publishing).hash do
          optional(:artifactory_url).filled(:string)
          optional(:package_scope).filled(:string)
          optional(:version).filled(:string)
          optional(:git_branch).filled(:string)
          optional(:slack_webhook_url).filled(:string)
        end
      end

      rule('frameworks').each do
        key.failure('must have at least one platform') if value[:platforms].empty?

        value[:platforms]&.each do |platform|
          key.failure("invalid platform: #{platform}") unless VALID_PLATFORMS.include?(platform)
        end

        value[:architectures]&.each_value do |archs|
          archs.each do |arch|
            key.failure("invalid architecture: #{arch}") unless VALID_ARCHITECTURES.include?(arch)
          end
        end
      end
    end
  end
end
