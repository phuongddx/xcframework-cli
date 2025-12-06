# frozen_string_literal: true

unless ENV['SKIP_COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
    minimum_coverage 80
  end
end

require 'xcframework_cli'
require 'pry'
require 'pry-byebug'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Suppress logger output during tests
  config.before do
    XCFrameworkCLI.configure_logger(quiet: true)
  end

  # Reset logger after tests
  config.after do
    XCFrameworkCLI.configure_logger(quiet: false, verbose: false)
  end
end
