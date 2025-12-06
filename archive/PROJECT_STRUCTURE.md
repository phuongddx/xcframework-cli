# XCFramework CLI - Project Structure

This document outlines the complete directory structure for the Ruby-based XCFramework CLI tool.

## 📁 Directory Layout

```
/Users/ddphuong/Projects/xcframework-cli/
│
├── bin/                                    # Executables
│   └── xcframework-cli                     # Main CLI executable
│
├── lib/                                    # Core library code
│   ├── xcframework_cli.rb                  # Main module entry point
│   └── xcframework_cli/                    # Module namespace
│       ├── version.rb                      # Version constant (0.1.0)
│       ├── cli.rb                          # Thor CLI interface
│       ├── config.rb                       # Configuration management
│       ├── builder.rb                      # XCFramework builder
│       ├── platform.rb                     # Platform definitions
│       ├── resource_manager.rb             # Resource bundle manager
│       ├── accessor_injector.rb            # Resource accessor injector
│       ├── publisher.rb                    # Artifactory publisher
│       ├── xcodebuild.rb                   # Xcodebuild wrapper
│       ├── logger.rb                       # Colored logger
│       └── utils.rb                        # Helper utilities
│
├── spec/                                   # RSpec tests
│   ├── spec_helper.rb                      # RSpec configuration
│   ├── support/                            # Test support files
│   │   ├── fixtures/                       # Test fixtures
│   │   └── shared_examples/                # Shared examples
│   ├── unit/                               # Unit tests
│   │   ├── config_spec.rb
│   │   ├── builder_spec.rb
│   │   ├── platform_spec.rb
│   │   ├── resource_manager_spec.rb
│   │   ├── accessor_injector_spec.rb
│   │   ├── publisher_spec.rb
│   │   ├── xcodebuild_spec.rb
│   │   └── logger_spec.rb
│   └── integration/                        # Integration tests
│       ├── build_spec.rb
│       ├── debug_spec.rb
│       └── release_spec.rb
│
├── templates/                              # Swift templates
│   └── resource_bundle_accessor.swift      # Custom resource accessor
│
├── config/                                 # Configuration files
│   ├── default.yml                         # Default configuration
│   └── example.yml                         # Example configuration
│
├── docs/                                   # Documentation
│   ├── ARCHITECTURE.md                     # Architecture details
│   ├── CONTRIBUTING.md                     # Contribution guide
│   ├── API.md                              # API documentation
│   └── MIGRATION.md                        # Migration from Bash
│
├── examples/                               # Usage examples
│   ├── basic_build.rb
│   ├── custom_config.rb
│   └── programmatic_usage.rb
│
├── .github/                                # GitHub configuration
│   └── workflows/                          # GitHub Actions
│       ├── ci.yml                          # CI pipeline
│       └── release.yml                     # Release automation
│
├── Gemfile                                 # Ruby dependencies
├── Gemfile.lock                            # Locked dependencies
├── xcframework-cli.gemspec                 # Gem specification
├── Rakefile                                # Rake tasks
├── .rubocop.yml                            # RuboCop configuration
├── .rspec                                  # RSpec configuration
├── .gitignore                              # Git ignore rules
├── README.md                               # Project README
├── IMPLEMENTATION_PLAN.md                  # This implementation plan
├── PROJECT_STRUCTURE.md                    # This file
├── CHANGELOG.md                            # Version history
└── LICENSE                                 # License file
```

## 📦 File Descriptions

### Executables (`bin/`)

#### `bin/xcframework-cli`
Main executable entry point. Sets up load path and invokes CLI.

```ruby
#\!/usr/bin/env ruby
require_relative '../lib/xcframework_cli'
XCFrameworkCLI::CLI.start(ARGV)
```

---

### Core Library (`lib/`)

#### `lib/xcframework_cli.rb`
Main module file that requires all components.

```ruby
require 'thor'
require 'colorize'
require 'yaml'

require_relative 'xcframework_cli/version'
require_relative 'xcframework_cli/logger'
require_relative 'xcframework_cli/config'
require_relative 'xcframework_cli/platform'
require_relative 'xcframework_cli/xcodebuild'
require_relative 'xcframework_cli/builder'
require_relative 'xcframework_cli/resource_manager'
require_relative 'xcframework_cli/accessor_injector'
require_relative 'xcframework_cli/publisher'
require_relative 'xcframework_cli/cli'
require_relative 'xcframework_cli/utils'

module XCFrameworkCLI
  class Error < StandardError; end
  class ConfigError < Error; end
  class BuildError < Error; end
  class PublishError < Error; end
end
```

#### `lib/xcframework_cli/version.rb`
Version constant.

```ruby
module XCFrameworkCLI
  VERSION = '0.1.0'
end
```

#### `lib/xcframework_cli/cli.rb`
Thor-based CLI interface with all commands.

**Size**: ~200 lines  
**Responsibilities**: Command routing, option parsing, help text

#### `lib/xcframework_cli/config.rb`
Configuration management with YAML loading and validation.

**Size**: ~150 lines  
**Responsibilities**: Load config, validate, resolve paths

#### `lib/xcframework_cli/builder.rb`
Core XCFramework builder orchestrating the build process.

**Size**: ~250 lines  
**Responsibilities**: Build pipeline, archive creation, XCFramework assembly

#### `lib/xcframework_cli/platform.rb`
Platform definitions and abstractions.

**Size**: ~100 lines  
**Responsibilities**: Platform constants, SDK paths, target triples

#### `lib/xcframework_cli/resource_manager.rb`
Resource bundle management.

**Size**: ~150 lines  
**Responsibilities**: Find bundles, copy into frameworks

#### `lib/xcframework_cli/accessor_injector.rb`
Custom resource accessor injection.

**Size**: ~150 lines  
**Responsibilities**: Replace accessor, recompile with swiftc

#### `lib/xcframework_cli/publisher.rb`
Artifactory publishing and Git operations.

**Size**: ~200 lines  
**Responsibilities**: Git tagging, Artifactory upload, Slack notifications

#### `lib/xcframework_cli/xcodebuild.rb`
Xcodebuild command wrapper.

**Size**: ~150 lines  
**Responsibilities**: Execute xcodebuild, format output, error handling

#### `lib/xcframework_cli/logger.rb`
Colored logging with progress indicators.

**Size**: ~100 lines  
**Responsibilities**: Colored output, spinners, timing

#### `lib/xcframework_cli/utils.rb`
Helper utilities and common functions.

**Size**: ~100 lines  
**Responsibilities**: File operations, shell commands, checksums

---

### Tests (`spec/`)

#### `spec/spec_helper.rb`
RSpec configuration with SimpleCov, mocks, and helpers.

```ruby
require 'simplecov'
SimpleCov.start

require 'xcframework_cli'
require 'pry'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
```

#### Unit Tests (`spec/unit/`)
One spec file per class, testing in isolation with mocks.

**Coverage Target**: 90%+

#### Integration Tests (`spec/integration/`)
End-to-end tests with real builds (if possible).

**Coverage Target**: Key workflows

---

### Configuration (`config/`)

#### `config/default.yml`
Default configuration values.

```yaml
project:
  root: "../../luz_epost_ios"
  workspace_root: "../../.."
  xcode_project: "luz_epost_ios.xcodeproj"

build:
  output_dir: "build"
  derived_data: "build/DerivedData"
  log_dir: "build/logs"

frameworks:
  - name: "ePostSDK"
    scheme: "ePostSDK"
  - name: "ePostPushNotificationSDK"
    scheme: "ePostPushNotificationSDK"

resource_bundles:
  - "ios_theme_ui_ios_theme_ui.bundle"
```

---

### Documentation (`docs/`)

#### `docs/ARCHITECTURE.md`
Detailed architecture documentation with diagrams.

#### `docs/CONTRIBUTING.md`
Guide for contributors: setup, testing, PR process.

#### `docs/API.md`
API documentation for programmatic usage.

#### `docs/MIGRATION.md`
Migration guide from Bash scripts to Ruby CLI.

---

### Package Files

#### `Gemfile`
Ruby dependencies.

```ruby
source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'pry'
  gem 'pry-byebug'
end
```

#### `xcframework-cli.gemspec`
Gem specification.

```ruby
require_relative 'lib/xcframework_cli/version'

Gem::Specification.new do |spec|
  spec.name          = 'xcframework-cli'
  spec.version       = XCFrameworkCLI::VERSION
  spec.authors       = ['Phuong Doan Duy']
  spec.email         = ['phuong@example.com']
  
  spec.summary       = 'CLI tool for building iOS XCFrameworks'
  spec.description   = 'Professional Ruby CLI for building XCFrameworks'
  spec.homepage      = 'https://github.com/example/xcframework-cli'
  spec.license       = 'Proprietary'
  
  spec.required_ruby_version = '>= 3.0.0'
  
  spec.files         = Dir['lib/**/*', 'bin/*', 'templates/*']
  spec.bindir        = 'bin'
  spec.executables   = ['xcframework-cli']
  spec.require_paths = ['lib']
  
  spec.add_dependency 'thor', '~> 1.3'
  spec.add_dependency 'colorize', '~> 1.1'
  spec.add_dependency 'tty-spinner', '~> 0.9'
  spec.add_dependency 'tty-prompt', '~> 0.23'
  spec.add_dependency 'dry-validation', '~> 1.10'
  
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.50'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20'
  spec.add_development_dependency 'simplecov', '~> 0.22'
end
```

#### `Rakefile`
Rake tasks for common operations.

```ruby
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: [:spec, :rubocop]

desc 'Run all tests'
task test: :spec

desc 'Run RuboCop'
task lint: :rubocop

desc 'Run RuboCop with auto-correct'
task 'lint:fix' do
  system 'rubocop -A'
end

desc 'Generate documentation'
task :docs do
  system 'yard doc'
end
```

---

## 📊 File Size Estimates

| Component | Files | Lines | Complexity |
|-----------|-------|-------|------------|
| CLI | 1 | ~200 | Medium |
| Config | 1 | ~150 | Low |
| Builder | 1 | ~250 | High |
| Platform | 1 | ~100 | Low |
| ResourceManager | 1 | ~150 | Medium |
| AccessorInjector | 1 | ~150 | Medium |
| Publisher | 1 | ~200 | Medium |
| Xcodebuild | 1 | ~150 | Medium |
| Logger | 1 | ~100 | Low |
| Utils | 1 | ~100 | Low |
| **Total** | **10** | **~1,550** | **Medium** |

**Comparison with Bash**: ~1,533 lines → ~1,550 lines (similar size, better structure)

---

## 🔄 Development Workflow

### Initial Setup
```bash
cd /Users/ddphuong/Projects/xcframework-cli
bundle install
```

### Running Tests
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/unit/         # Run unit tests only
bundle exec rspec spec/integration/  # Run integration tests only
```

### Linting
```bash
bundle exec rubocop                  # Check code style
bundle exec rubocop -A               # Auto-fix issues
```

### Running CLI (Development)
```bash
bundle exec bin/xcframework-cli --help
bundle exec bin/xcframework-cli build ePostSDK --simulator
```

### Building Gem
```bash
gem build xcframework-cli.gemspec
gem install xcframework-cli-0.1.0.gem
```

---

## 📝 Notes

- Keep classes under 200 lines for maintainability
- Use dependency injection for testability
- Mock external commands in tests
- Follow Ruby style guide (RuboCop)
- Document all public methods with YARD
- Write tests before implementation (TDD)

---

**Last Updated**: December 4, 2025  
**Version**: 1.0.0

