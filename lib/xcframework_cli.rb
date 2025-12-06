# frozen_string_literal: true

require_relative 'xcframework_cli/version'
require_relative 'xcframework_cli/errors'
require_relative 'xcframework_cli/utils/logger'
require_relative 'xcframework_cli/utils/spinner'
require_relative 'xcframework_cli/config/loader'
require_relative 'xcframework_cli/config/schema'
require_relative 'xcframework_cli/config/defaults'
require_relative 'xcframework_cli/platform/registry'
require_relative 'xcframework_cli/xcodebuild/wrapper'
require_relative 'xcframework_cli/builder/cleaner'
require_relative 'xcframework_cli/builder/archiver'
require_relative 'xcframework_cli/builder/xcframework'
require_relative 'xcframework_cli/builder/orchestrator'

# CLI
require_relative 'xcframework_cli/cli/runner'
require_relative 'xcframework_cli/cli/commands/build'

# Main module for XCFramework CLI
module XCFrameworkCLI
  class << self
    # Load configuration from file
    def load_config(path: nil)
      Config::Loader.load(path: path)
    end

    # Get logger instance
    def logger
      Utils::Logger
    end

    # Configure logger settings
    def configure_logger(verbose: false, quiet: false)
      Utils::Logger.verbose = verbose
      Utils::Logger.quiet = quiet
    end
  end
end
