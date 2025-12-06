# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

# RSpec tasks
RSpec::Core::RakeTask.new(:spec)

# RuboCop tasks
RuboCop::RakeTask.new

# Default task
task default: %i[spec rubocop]

# Test task without coverage requirement
desc 'Run tests without coverage requirement'
task :test do
  ENV['SKIP_COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

# Lint task
desc 'Run RuboCop linter'
task :lint do
  Rake::Task['rubocop'].execute
end

# Auto-fix linting issues
desc 'Auto-fix RuboCop issues'
task :lint_fix do
  sh 'bundle exec rubocop -A'
end

# Console task for interactive testing
desc 'Open interactive console with gem loaded'
task :console do
  require 'pry'
  require_relative 'lib/xcframework_cli'
  Pry.start
end
