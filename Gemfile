# frozen_string_literal: true

source 'https://rubygems.org'

# Specify Ruby version
ruby '>= 3.0.0'

# Core dependencies
gem 'colorize', '~> 1.1'          # Terminal colors
gem 'dry-validation', '~> 1.10'   # Configuration validation
gem 'thor', '~> 1.3'              # CLI framework
gem 'tty-prompt', '~> 0.23'       # Interactive prompts
gem 'tty-spinner', '~> 0.9'       # Progress indicators
gem 'yaml', '~> 0.3' # YAML parsing

# Development dependencies
group :development, :test do
  gem 'pry', '~> 0.14'             # Debugging
  gem 'pry-byebug', '~> 3.10'      # Debugger
  gem 'rake', '~> 13.0'            # Task runner
  gem 'rspec', '~> 3.12'           # Testing framework
  gem 'rubocop', '~> 1.50'         # Code linting
  gem 'rubocop-rspec', '~> 2.20'   # RSpec linting
  gem 'simplecov', '~> 0.22'       # Code coverage
  gem 'yard', '~> 0.9'             # Documentation
end

# Test dependencies
group :test do
  gem 'rspec-mocks', '~> 3.12'     # Mocking
  gem 'vcr', '~> 6.1'              # HTTP recording
  gem 'webmock', '~> 3.18'         # HTTP mocking
end
