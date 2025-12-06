# frozen_string_literal: true

require_relative 'spec_helper'

# Integration test configuration
RSpec.configure do |config|
  # Tag integration tests
  config.filter_run_excluding integration: true unless ENV['RUN_INTEGRATION_TESTS']
end
