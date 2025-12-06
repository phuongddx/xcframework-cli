# frozen_string_literal: true

module XCFrameworkCLI
  # Base error class for all XCFramework CLI errors
  class Error < StandardError
    attr_reader :suggestions

    def initialize(message, suggestions: [])
      super(message)
      @suggestions = suggestions
    end

    # Format error message with suggestions
    def full_message
      msg = message
      unless suggestions.empty?
        msg += "\n\nSuggestions:"
        suggestions.each { |s| msg += "\n  • #{s}" }
      end
      msg
    end
  end

  # Configuration-related errors
  class ConfigError < Error; end
  class ValidationError < ConfigError; end
  class FileNotFoundError < ConfigError; end

  # Build-related errors
  class BuildError < Error; end
  class XcodebuildError < BuildError; end
  class ArchiveError < BuildError; end
  class XCFrameworkError < BuildError; end

  # Platform-related errors
  class PlatformError < Error; end
  class UnsupportedPlatformError < PlatformError; end
  class InvalidArchitectureError < PlatformError; end

  # Resource-related errors
  class ResourceError < Error; end
  class BundleNotFoundError < ResourceError; end
  class InjectionError < ResourceError; end

  # Publishing-related errors
  class PublishError < Error; end
  class ArtifactoryError < PublishError; end
  class GitError < PublishError; end
end

