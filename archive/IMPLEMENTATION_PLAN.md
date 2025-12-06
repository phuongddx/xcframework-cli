# XCFramework CLI - Ruby Implementation Plan

## 📋 Overview

This document outlines the detailed plan to convert the existing Bash-based xcframework-cli tool into a professional Ruby CLI application.

**Project Location**: `/Users/ddphuong/Projects/xcframework-cli`

**Original Tool**: `tools/xcframework-cli` (Bash scripts, ~1,533 lines)

---

## 🎉 Recent Updates (December 2025)

### ✅ Bash Scripts Refactored to be Framework-Agnostic

The existing Bash scripts have been **successfully refactored** to remove all hardcoded project-specific references. This work provides a solid foundation for the Ruby rewrite.

**Key Improvements:**

- ✅ Removed all hardcoded references to `ePostSDK`, `luz_epost_ios`, `ios_theme_ui`
- ✅ Implemented environment variable-based configuration system
- ✅ Made all scripts work with any iOS XCFramework project
- ✅ Added comprehensive documentation (CONFIGURATION.md, MIGRATION_GUIDE.md)
- ✅ Created example configuration file (config.example.sh)

**Files Updated:**

- `config.sh` - Now uses `XCODE_PROJECT_NAME`, `FRAMEWORK_NAMES`, `SDK_OUTPUT_DIR_NAME`
- `debug.sh` - Accepts framework names as command-line arguments
- `release.sh` - Accepts framework names as command-line arguments
- `inject-resource-accessor.sh` - Uses configurable `RESOURCE_MODULE_NAME`
- `publish_to_artifactory.sh` - Uses configurable `PACKAGE_SCOPE`
- `setup.sh` - Removed project-specific branding

**Documentation Added:**

- [CONFIGURATION.md](CONFIGURATION.md) - Complete configuration guide
- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Migration from old to new config
- [config.example.sh](config.example.sh) - Example configuration template

**Impact on Ruby Implementation:**
The Ruby rewrite will build upon this improved configuration system, maintaining the framework-agnostic approach and enhancing it with better validation, type safety, and user experience.

---

## 🎯 Project Goals

1. **Maintain feature parity** with existing Bash scripts
2. **Preserve framework-agnostic design** from recent Bash refactoring
3. **Improve maintainability** through OOP design
4. **Better error handling** and user feedback
5. **Enhanced testability** with RSpec (90%+ coverage)
6. **Professional CLI UX** with Thor framework
7. **Enhanced configuration** with validation and better defaults
8. **Cross-platform compatibility** (macOS focus)

---

## 📊 Current State Analysis

### Existing Bash Scripts (Refactored)

| Script                      | Lines | Purpose                    | Status                    |
| --------------------------- | ----- | -------------------------- | ------------------------- |
| config.sh                   | 136   | Centralized configuration  | ✅ Framework-agnostic     |
| create-xcframework.sh       | 625   | Core XCFramework builder   | ✅ Uses config vars       |
| debug.sh                    | 147   | Debug build wrapper        | ✅ Accepts framework args |
| release.sh                  | 109   | Release build + publish    | ✅ Accepts framework args |
| copy-resource-bundle.sh     | 221   | Resource bundle management | ✅ Uses config vars       |
| inject-resource-accessor.sh | 218   | Custom accessor injection  | ✅ Configurable module    |
| publish_to_artifactory.sh   | 117   | Artifactory publishing     | ✅ Configurable scope     |
| setup.sh                    | 80    | Dependency installation    | ✅ Generic branding       |

**Total**: ~1,653 lines of Bash code (framework-agnostic)

### Key Features

- ✅ Build XCFrameworks for iOS (device + simulator)
- ✅ **Framework-agnostic configuration** (NEW)
- ✅ **Environment variable-based setup** (NEW)
- ✅ **Command-line framework selection** (NEW)
- ✅ Resource bundle copying and management
- ✅ Custom resource accessor injection
- ✅ Artifactory publishing with Git tagging
- ✅ Slack notifications (optional)
- ✅ Checksum generation
- ✅ Build output formatting (xcbeautify)
- ✅ Incremental builds (--no-clean)

---

## 📐 Architecture Design

### Project Structure

\`\`\`
/Users/ddphuong/Projects/xcframework-cli/
├── bin/
│ └── xcframework-cli # Executable entry point
├── lib/
│ ├── xcframework_cli.rb # Main module
│ ├── xcframework_cli/
│ │ ├── version.rb # Version constant
│ │ ├── cli.rb # CLI interface (Thor)
│ │ ├── config.rb # Configuration management
│ │ ├── builder.rb # Core XCFramework builder
│ │ ├── platform.rb # Platform abstraction
│ │ ├── resource_manager.rb # Resource bundle handling
│ │ ├── accessor_injector.rb # Resource accessor injection
│ │ ├── publisher.rb # Artifactory publishing
│ │ ├── xcodebuild.rb # Xcodebuild wrapper
│ │ ├── logger.rb # Colored output logger
│ │ └── utils.rb # Helper utilities
├── spec/
│ ├── spec_helper.rb
│ ├── config_spec.rb
│ ├── builder_spec.rb
│ ├── platform_spec.rb
│ ├── resource_manager_spec.rb
│ ├── accessor_injector_spec.rb
│ ├── publisher_spec.rb
│ ├── xcodebuild_spec.rb
│ └── integration/
│ └── build_spec.rb
├── templates/
│ └── resource_bundle_accessor.swift
├── config/
│ └── default.yml # Default configuration
├── Gemfile
├── Gemfile.lock
├── xcframework-cli.gemspec
├── Rakefile
├── README.md
├── ARCHITECTURE.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
\`\`\`

---

## 🔧 Technical Stack

### Core Dependencies

\`\`\`ruby

# Gemfile

source 'https://rubygems.org'

gem 'thor', '~> 1.3' # CLI framework
gem 'colorize', '~> 1.1' # Terminal colors
gem 'tty-spinner', '~> 0.9' # Progress indicators
gem 'tty-prompt', '~> 0.23' # Interactive prompts
gem 'dry-validation', '~> 1.10' # Configuration validation
gem 'yaml', '~> 0.2' # YAML parsing

group :development, :test do
gem 'rspec', '~> 3.12' # Testing framework
gem 'rubocop', '~> 1.50' # Code linting
gem 'rubocop-rspec', '~> 2.20' # RSpec linting
gem 'simplecov', '~> 0.22' # Code coverage
gem 'pry', '~> 0.14' # Debugging
gem 'pry-byebug', '~> 3.10' # Debugging with breakpoints
end
\`\`\`

### System Requirements

- Ruby 3.0+
- macOS 12.0+ (Monterey or later)
- Xcode 14.0+
- Xcode Command Line Tools
- Homebrew (optional, for xcbeautify)

---

## 📦 Core Components

### 1. CLI Interface (`lib/xcframework_cli/cli.rb`)

**Responsibilities:**

- Command routing and parsing
- Help documentation
- Version display
- Interactive mode
- Framework-agnostic command handling

**Design Principles (from Bash refactoring):**

- ✅ Accept framework names as arguments (not hardcoded)
- ✅ Support multiple frameworks in single command
- ✅ Fall back to configuration when no frameworks specified
- ✅ Provide clear error messages for missing configuration

**Commands:**
\`\`\`ruby
class XCFrameworkCLI::CLI < Thor
desc "build FRAMEWORK_NAMES...", "Build one or more XCFrameworks"
long_desc <<-LONGDESC
Build XCFrameworks for the specified frameworks.

    If no framework names are provided, builds all frameworks from configuration.

    Examples:
      $ xcframework-cli build MySDK --simulator
      $ xcframework-cli build MySDK AnotherSDK --all
      $ xcframework-cli build --device  # Builds all from config

LONGDESC
option :all, type: :boolean, default: true, desc: "Build for device + simulator"
option :device, type: :boolean, desc: "Build for device only"
option :simulator, type: :boolean, desc: "Build for simulator only"
option :output_dir, type: :string, desc: "Custom output directory"
option :no_clean, type: :boolean, desc: "Skip cleaning before build"
option :verbose, type: :boolean, desc: "Verbose output"
option :checksum, type: :boolean, desc: "Generate SHA256 checksum"
def build(\*framework_names) # Build logic - accepts multiple frameworks # Falls back to config.frameworks.default if none provided
end

desc "debug FRAMEWORK_NAMES...", "Build frameworks for debugging"
long_desc <<-LONGDESC
Build frameworks in debug mode.

    Examples:
      $ xcframework-cli debug --simulator
      $ xcframework-cli debug MySDK AnotherSDK --all

LONGDESC
option :all, type: :boolean, default: true
option :device, type: :boolean
option :simulator, type: :boolean
def debug(\*framework_names) # Debug build logic - framework-agnostic
end

desc "release FRAMEWORK_NAMES...", "Build and publish frameworks"
long_desc <<-LONGDESC
Build frameworks and publish to Artifactory.

    Requires: VERSION, ARTIFACTORY_URL, PACKAGE_SCOPE environment variables

    Examples:
      $ xcframework-cli release MySDK
      $ xcframework-cli release  # Publishes all from config

LONGDESC
def release(\*framework_names) # Release logic - framework-agnostic
end

desc "clean", "Clean build artifacts"
option :all, type: :boolean, default: true
option :derived_data, type: :boolean
option :xcframeworks, type: :boolean
def clean # Clean logic
end

desc "setup", "Install build dependencies"
def setup # Setup logic (xcbeautify, etc.)
end

desc "config SUBCOMMAND", "Manage configuration"
subcommand "config", ConfigCLI

# Subcommands: show, validate, init

end
\`\`\`

---

### 2. Configuration (`lib/xcframework_cli/config.rb`)

**Responsibilities:**

- Load from config.yml or environment variables
- Path resolution (PROJECT_ROOT, BUILD_DIR, etc.)
- Framework definitions (framework-agnostic)
- Validation with dry-validation
- Export to environment variables
- Support multiple configuration sources (file, env, CLI args)

**Design Principles (from Bash refactoring):**

- ✅ No hardcoded project names
- ✅ Environment variables take precedence
- ✅ Sensible defaults for all settings
- ✅ Support for multiple frameworks
- ✅ Configurable package scopes for publishing

**Configuration Structure:**
\`\`\`yaml

# config/default.yml (framework-agnostic template)

project:

# Xcode project name (without .xcodeproj extension)

# Can be overridden with XCODE_PROJECT_NAME env var

name: "${XCODE_PROJECT_NAME:-MyProject}"

# Project root directory

root: "."

# Workspace root (for multi-project setups)

workspace_root: ".."

build:

# Output directory for XCFrameworks

# Can be overridden with SDK_OUTPUT_DIR_NAME env var

output_dir: "${SDK_OUTPUT_DIR_NAME:-SDKOutput}"

# Derived data directory

derived_data: "build/DerivedData"

# Build logs directory

log_dir: "build/logs"

frameworks:

# Framework names can be specified via:

# 1. FRAMEWORK_NAMES environment variable (space-separated)

# 2. Command-line arguments

# 3. This configuration file

# Example: FRAMEWORK_NAMES="MySDK UtilsSDK NetworkSDK"

default: "${FRAMEWORK_NAMES:-}"

# Optional: Define framework-specific settings

# configurations:

# - name: "MySDK"

# scheme: "MySDK"

# custom_output_dir: "custom/path"

# - name: "UtilsSDK"

# scheme: "UtilsSDK"

resource_bundles:

# Module name for resource bundle accessor injection

# Can be overridden with RESOURCE_MODULE_NAME env var

module_name: "${RESOURCE_MODULE_NAME:-}"

# Resource bundle patterns (optional)

# patterns:

# - "\*\_resources.bundle"

# - "\*\_theme_ui.bundle"

templates:
resource_accessor: "templates/resource_bundle_accessor.swift"

artifactory:

# All values support environment variable substitution

url: "${ARTIFACTORY_URL}"
  username: "${ARTIFACTORY_USERNAME}"
token: "${JFROG_ACCESS_TOKEN}"

# Package scope (e.g., "com.company", "io.github.username")

# Replaces hardcoded "axon" from old implementation

package_scope: "${PACKAGE_SCOPE:-com.example}"

git:

# Git branch for releases

branch: "${GIT_BRANCH:-master}"

slack:

# Optional Slack webhook for notifications

webhook_url: "${SLACK_WEBHOOK_URL:-}"

# Version for publishing

version: "${VERSION:-1.0.0}"
\`\`\`

**Ruby Implementation Notes:**

- Use `dry-validation` for schema validation
- Support environment variable expansion (${VAR:-default})
- Merge configuration from multiple sources (file → env → CLI)
- Validate required fields based on command (e.g., publishing requires PACKAGE_SCOPE)
- Provide helpful error messages for missing configuration

---

### 3. Builder (`lib/xcframework_cli/builder.rb`)

**Responsibilities:**

- Orchestrate build process
- Platform-specific builds (device/simulator)
- Archive creation
- XCFramework assembly
- Checksum generation
- Build artifact cleanup

**Build Pipeline:**

1. Validate configuration
2. Clean previous builds (optional)
3. Build device archive (conditional)
4. Build simulator archive (conditional)
5. Copy resource bundles
6. Inject custom accessors
7. Create XCFramework
8. Generate checksums
9. Cleanup artifacts

**Key Methods:**
\`\`\`ruby
class XCFrameworkCLI::Builder
def initialize(framework_name, options = {})
def build
def build_archive(platform)
def copy_resource_bundles(platform)
def inject_resource_accessors(platform)
def create_xcframework
def generate_checksum
def cleanup
end
\`\`\`

---

### 4. Platform (`lib/xcframework_cli/platform.rb`)

**Responsibilities:**

- Platform definitions (iOS Device, iOS Simulator)
- SDK path resolution
- Target triple generation
- Archive suffix naming

**Platform Definitions:**
\`\`\`ruby
class XCFrameworkCLI::Platform
IOS_DEVICE = Platform.new(
name: "iOS Device",
sdk: "iphoneos",
destination: "generic/platform=iOS",
arch: "arm64",
target_triple: "arm64-apple-ios16.0",
archive_suffix: "iOS"
)

IOS_SIMULATOR = Platform.new(
name: "iOS Simulator",
sdk: "iphonesimulator",
destination: "generic/platform=iOS Simulator",
arch: "arm64",
target_triple: "arm64-apple-ios16.0-simulator",
archive_suffix: "iOS-Simulator"
)
end
\`\`\`

---

### 5. Resource Manager (`lib/xcframework_cli/resource_manager.rb`)

**Responsibilities:**

- Find resource bundles in build artifacts
- Copy bundles into framework
- Validate bundle structure
- Handle multiple bundles

**Key Methods:**
\`\`\`ruby
class XCFrameworkCLI::ResourceManager
def initialize(config)
def copy_bundles(archive_path, platform, framework_name)
def find_bundle(bundle_name, platform)
def validate_bundle(bundle_path)
end
\`\`\`

---

### 6. Accessor Injector (`lib/xcframework_cli/accessor_injector.rb`)

**Responsibilities:**

- Find SPM-generated resource_bundle_accessor.swift
- Replace with custom template
- Recompile .o file with swiftc
- Platform-specific compilation

**Key Methods:**
\`\`\`ruby
class XCFrameworkCLI::AccessorInjector
def initialize(config)
def inject(output_dir, platform)
def find_accessor_file(output_dir)
def replace_with_template(accessor_file)
def recompile_object_file(accessor_file, platform)
end
\`\`\`

---

### 7. Publisher (`lib/xcframework_cli/publisher.rb`)

**Responsibilities:**

- Git operations (commit, tag, push)
- Artifactory authentication
- Package publishing
- Slack notifications
- Changelog extraction

**Key Methods:**
\`\`\`ruby
class XCFrameworkCLI::Publisher
def initialize(config)
def publish(version)
def commit_and_tag(version)
def publish_to_artifactory(version)
def send_slack_notification(version, changelog)
def extract_changelog(version)
end
\`\`\`

---

### 8. Xcodebuild Wrapper (`lib/xcframework_cli/xcodebuild.rb`)

**Responsibilities:**

- Execute xcodebuild commands
- Stream output with formatting (xcbeautify)
- Error handling and parsing
- Build settings management

**Key Methods:**
\`\`\`ruby
class XCFrameworkCLI::Xcodebuild
def initialize(logger, verbose: false)
def archive(project:, scheme:, destination:, archive_path:, settings: {})
def create_xcframework(frameworks:, output:)
def clean(project:, scheme:)
def format_output(command)
end
\`\`\`

---

### 9. Logger (`lib/xcframework_cli/logger.rb`)

**Responsibilities:**

- Colored output (success, error, warning, info)
- Progress indicators
- Step tracking (1/5, 2/5, etc.)
- Timing information
- Verbose mode

**Key Methods:**
\`\`\`ruby
class XCFrameworkCLI::Logger
def success(message)
def error(message)
def warning(message)
def info(message)
def header(message)
def step(current, total, message)
def spinner(message, &block)
def time_elapsed(seconds)
end
\`\`\`

---

## 🎨 CLI Commands

### Build Command

\`\`\`bash
xcframework-cli build ePostSDK [OPTIONS]

Options:
--all Build for device + simulator (default)
--device Build for device only
--simulator Build for simulator only
--output-dir PATH Custom output directory
--no-clean Skip cleaning build artifacts
--verbose Enable verbose output
--checksum Generate SHA256 checksum

Examples:
xcframework-cli build ePostSDK
xcframework-cli build ePostSDK --simulator --verbose
xcframework-cli build ePostPushNotificationSDK --device --checksum
\`\`\`

### Debug Command

\`\`\`bash
xcframework-cli debug [OPTIONS]

Options:
--all Build both SDKs for all platforms (default)
--device Build for device only
--simulator Build for simulator only

Examples:
xcframework-cli debug
xcframework-cli debug --simulator
\`\`\`

### Release Command

\`\`\`bash
xcframework-cli release

# Builds both SDKs and publishes to Artifactory

# Requires: VERSION environment variable

\`\`\`

### Clean Command

\`\`\`bash
xcframework-cli clean [OPTIONS]

Options:
--all Clean all build artifacts (default)
--derived-data Clean DerivedData only
--xcframeworks Clean XCFrameworks only

Examples:
xcframework-cli clean
xcframework-cli clean --derived-data
\`\`\`

### Setup Command

\`\`\`bash
xcframework-cli setup

# Installs dependencies:

# - Homebrew (if not installed)

# - xcbeautify (for formatted output)

\`\`\`

### Config Command

\`\`\`bash
xcframework-cli config show # Display current configuration
xcframework-cli config validate # Validate configuration
xcframework-cli config path # Show config file path
\`\`\`

---

## 📝 Implementation Phases

### Phase 1: Foundation (Week 1)

**Goal**: Set up project structure and basic infrastructure

- [ ] Initialize Ruby project structure
- [ ] Create Gemfile with dependencies
- [ ] Set up RSpec testing framework
- [ ] Set up RuboCop linting
- [ ] Implement `Config` class with YAML loading
- [ ] Implement `Logger` class with colored output
- [ ] Create basic CLI skeleton with Thor
- [ ] Write unit tests for Config and Logger
- [ ] Set up CI/CD pipeline (GitHub Actions)

**Deliverables:**

- Working project structure
- Config loading from YAML
- Colored logging output
- Basic CLI help command
- 90%+ test coverage for Config and Logger

---

### Phase 2: Core Building (Week 2)

**Goal**: Implement core XCFramework building functionality

- [ ] Implement `Platform` class with iOS definitions
- [ ] Implement `Xcodebuild` wrapper class
- [ ] Implement `Builder` class (basic build flow)
- [ ] Add device build support
- [ ] Add simulator build support
- [ ] Add XCFramework creation
- [ ] Add checksum generation
- [ ] Write unit tests for Platform, Xcodebuild, Builder
- [ ] Integration test: Build simple framework

**Deliverables:**

- Working build command
- Device + simulator builds
- XCFramework creation
- Checksum generation
- 85%+ test coverage

---

### Phase 3: Resource Management (Week 3)

**Goal**: Add resource bundle and accessor injection support

- [ ] Implement `ResourceManager` class
- [ ] Implement `AccessorInjector` class
- [ ] Integrate resource copying into Builder
- [ ] Integrate accessor injection into Builder
- [ ] Add template file handling
- [ ] Write unit tests for resource handling
- [ ] Integration test: Build with resources
- [ ] Test with ios_theme_ui bundle

**Deliverables:**

- Resource bundle copying
- Custom accessor injection
- Template management
- 85%+ test coverage

---

### Phase 4: Publishing & Polish (Week 4)

**Goal**: Add publishing and complete all CLI commands

- [ ] Implement `Publisher` class
- [ ] Add Git operations (commit, tag, push)
- [ ] Add Artifactory publishing
- [ ] Add Slack notifications
- [ ] Implement debug command
- [ ] Implement release command
- [ ] Implement clean command
- [ ] Implement setup command
- [ ] Implement config command
- [ ] Write comprehensive tests
- [ ] Write README documentation
- [ ] Write ARCHITECTURE documentation

**Deliverables:**

- Complete CLI with all commands
- Publishing to Artifactory
- Slack notifications
- Complete documentation
- 90%+ test coverage

---

### Phase 5: Migration & Testing (Week 5)

**Goal**: Validate against Bash scripts and prepare for production

- [ ] Parallel testing with Bash scripts
- [ ] Compare build outputs (checksums, structure)
- [ ] Performance benchmarking
- [ ] Fix any discrepancies
- [ ] User acceptance testing with team
- [ ] Create migration guide
- [ ] Add deprecation warnings to Bash scripts
- [ ] Update CI/CD to use Ruby CLI
- [ ] Monitor production usage

**Deliverables:**

- Validated feature parity
- Performance metrics
- Migration guide
- Production-ready tool

---

## 🧪 Testing Strategy

### Unit Tests

**Coverage Target**: 90%+

- Test each class in isolation
- Mock external dependencies (xcodebuild, git, curl)
- Test error handling and edge cases
- Test configuration validation
- Test path resolution

**Example:**
\`\`\`ruby
RSpec.describe XCFrameworkCLI::Config do
describe '#load' do
it 'loads configuration from YAML file'
it 'resolves environment variables'
it 'validates required fields'
it 'raises error for invalid config'
end
end
\`\`\`

### Integration Tests

**Coverage Target**: Key workflows

- Test full build pipeline
- Test with real Xcode project (if available)
- Verify XCFramework structure
- Test resource bundle copying
- Test accessor injection

**Example:**
\`\`\`ruby
RSpec.describe 'Build Integration' do
it 'builds XCFramework for simulator' do # Run full build # Verify output structure # Check for resource bundles
end
end
\`\`\`

### Acceptance Tests

**Manual Testing Checklist (Framework-Agnostic)**

- [ ] Build single framework successfully
- [ ] Build multiple frameworks in one command
- [ ] Build with --simulator flag
- [ ] Build with --device flag
- [ ] Build with --all flag
- [ ] Build with framework names from environment variable
- [ ] Build with framework names from CLI arguments
- [ ] Build with framework names from config file
- [ ] Resource bundles copied correctly (when configured)
- [ ] Custom accessors injected (when module name provided)
- [ ] Checksums generated
- [ ] Publish to Artifactory (staging) with custom package scope
- [ ] Slack notification sent (when webhook configured)
- [ ] Compare output with Bash scripts
- [ ] Test with different project names (not just ePost)
- [ ] Verify error messages for missing configuration

---

## 📊 Success Metrics

### Functional Requirements

- ✅ **Feature Parity**: All Bash script features working
- ✅ **Correctness**: XCFrameworks identical to Bash output
- ✅ **Reliability**: 100% success rate on CI/CD

### Non-Functional Requirements

- ✅ **Performance**: Build time within 10% of Bash scripts
- ✅ **Code Quality**: RuboCop score > 95%
- ✅ **Test Coverage**: > 90%
- ✅ **Documentation**: Complete README and inline docs
- ✅ **Maintainability**: Clear OOP design, < 200 lines per class

### User Experience

- ✅ **CLI UX**: Intuitive commands and helpful error messages
- ✅ **Output**: Colored, formatted, progress indicators
- ✅ **Help**: Comprehensive help documentation
- ✅ **Errors**: Clear error messages with suggestions

---

## 🚀 Migration Strategy

### Current Status: Bash Scripts Ready for Any Project

**✅ Completed (December 2025):**

- Bash scripts refactored to be framework-agnostic
- All hardcoded project names removed
- Environment variable-based configuration implemented
- Comprehensive documentation created (CONFIGURATION.md, MIGRATION_GUIDE.md)
- Scripts now work with any iOS XCFramework project

**Impact:**

- The Bash scripts are now production-ready for any project
- No urgency to migrate to Ruby (Bash scripts are maintainable)
- Ruby rewrite can focus on enhanced UX and features
- Migration can be gradual and low-risk

### Gradual Migration Approach

**Phase 0: Current State** (✅ Complete)

- Framework-agnostic Bash scripts in production
- Full documentation and examples
- Works with any iOS project

**Week 1-4**: Ruby Development

- Develop Ruby CLI in parallel with Bash scripts
- Maintain framework-agnostic design from Bash refactoring
- No changes to existing workflows
- Focus on enhanced UX and validation

**Week 5**: Beta Testing

- Select 2-3 developers for beta testing
- Run both tools side-by-side
- Collect feedback and fix issues
- Verify framework-agnostic behavior

**Week 6**: Parallel Deployment

- Deploy Ruby CLI to CI/CD
- Run both tools in parallel
- Compare outputs and performance
- Monitor error rates

**Week 7**: Primary Tool

- Switch to Ruby CLI as default
- Keep Bash scripts as fallback
- Add `--legacy` flag to use Bash

**Week 8**: Deprecation (Optional)

- Announce Bash script deprecation (if desired)
- Update all documentation
- Keep Bash scripts as reference implementation

### Rollback Plan

**If issues arise:**

1. Immediately switch back to Bash scripts
2. Investigate and fix Ruby CLI issues
3. Re-test thoroughly
4. Attempt migration again

**Rollback Triggers:**

- Build failure rate > 5%
- Performance degradation > 20%
- Critical bugs affecting releases
- Team consensus to rollback

**Note:** With the improved Bash scripts, there's less pressure to migrate. The Ruby implementation should provide clear value-add (better UX, validation, testing) rather than just being a rewrite.

---

## 📚 Documentation Plan

### README.md

- Installation instructions
- Quick start guide
- Command reference
- Configuration guide
- Examples
- Troubleshooting
- FAQ

### ARCHITECTURE.md

- Design decisions
- Class diagrams
- Component interactions
- Extension points
- Performance considerations

### CONTRIBUTING.md

- Development setup
- Running tests
- Code style guide
- Pull request process
- Release process

### CHANGELOG.md

- Version history
- Breaking changes
- New features
- Bug fixes
- Migration notes

### API Documentation

- YARD documentation for all classes
- Method signatures and parameters
- Return values and exceptions
- Usage examples
- Internal documentation

### Migration Guide

- Bash → Ruby command mapping
- Configuration changes
- Environment variable changes
- CI/CD integration updates
- Troubleshooting common issues

---

## 🔒 Security Considerations

### Credentials Management

- ✅ Use environment variables for sensitive data
- ✅ Never hardcode credentials
- ✅ Support .env files for local development
- ✅ Validate credential presence before use
- ✅ Mask credentials in logs

### Input Validation

- ✅ Sanitize all user inputs
- ✅ Validate file paths (prevent directory traversal)
- ✅ Validate framework names (alphanumeric only)
- ✅ Validate version strings
- ✅ Validate URLs

### File Operations

- ✅ Validate paths before operations
- ✅ Use absolute paths internally
- ✅ Check file permissions
- ✅ Handle symlinks safely
- ✅ Clean up temporary files

### Git Operations

- ✅ Verify repository state before push
- ✅ Validate branch names
- ✅ Check for uncommitted changes
- ✅ Verify remote URLs
- ✅ Handle authentication errors

### Artifactory

- ✅ Secure token storage
- ✅ HTTPS only
- ✅ Validate package integrity
- ✅ Handle authentication failures
- ✅ Rate limiting

---

## ⚡ Performance Optimizations

### Build Performance

- ✅ **Parallel Builds**: Use threads for independent operations
- ✅ **Caching**: Cache SDK paths, configuration
- ✅ **Incremental Builds**: Support `--no-clean` effectively
- ✅ **Smart Cleanup**: Only clean what's necessary

### Output Performance

- ✅ **Streaming**: Real-time xcodebuild output
- ✅ **Buffering**: Buffer log writes
- ✅ **Formatting**: Lazy formatting with xcbeautify

### Memory Management

- ✅ **Streaming**: Stream large files instead of loading
- ✅ **Cleanup**: Clean up temporary files promptly
- ✅ **Garbage Collection**: Explicit GC for long-running tasks

### Benchmarking

- Measure build times for each phase
- Compare with Bash script performance
- Profile Ruby code for bottlenecks
- Optimize hot paths

**Target Performance:**

- Total build time: Within 10% of Bash scripts
- Memory usage: < 100MB
- Startup time: < 1 second

---

## 🎯 Next Steps

### ✅ Completed: Bash Script Refactoring (December 2025)

1. ✅ Removed all hardcoded project-specific references
2. ✅ Implemented environment variable-based configuration
3. ✅ Updated all scripts to be framework-agnostic
4. ✅ Created comprehensive documentation (CONFIGURATION.md, MIGRATION_GUIDE.md)
5. ✅ Created example configuration (config.example.sh)
6. ✅ Updated README with quick start guide
7. ✅ Updated IMPLEMENTATION_PLAN with refactoring details

**Impact:** The Bash scripts are now production-ready for any iOS XCFramework project!

### Immediate Actions (This Week)

1. ✅ Review this plan with the team
2. ✅ Get approval for architecture and dependencies
3. ✅ Set up development environment
4. ✅ Create initial project structure
5. ✅ Initialize Git repository
6. ✅ Refactor Bash scripts to be framework-agnostic

### Week 1 Tasks (Ruby Implementation)

1. Create Gemfile and install dependencies
2. Set up RSpec and RuboCop
3. Implement Config class (framework-agnostic, based on Bash refactoring)
4. Implement Logger class
5. Create basic CLI skeleton (accept framework names as arguments)
6. Write initial tests (test with multiple framework names)

### Questions to Resolve

1. Should we support additional platforms (macOS, tvOS, watchOS)?
2. ~~Do we need a configuration file or rely on environment variables?~~ ✅ **Resolved**: Support both (based on Bash refactoring)
3. Should we add a `--dry-run` mode?
4. Do we want plugin support for custom build steps?
5. Should we integrate with Fastlane?
6. What's the preferred Ruby version (3.0, 3.1, 3.2)?
7. Should we publish as a gem or keep it internal?

---

## 📚 Related Documentation

- **[CONFIGURATION.md](CONFIGURATION.md)** - Complete configuration guide for Bash scripts
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Migration from old to new configuration
- **[config.example.sh](config.example.sh)** - Example configuration template
- **[README.md](README.md)** - Main project documentation

---

## 📞 Contact & Support

**Project Lead**: Phuong Doan Duy
**Repository**: `/Users/ddphuong/Projects/xcframework-cli`
**Original Tool**: `tools/xcframework-cli` (now framework-agnostic)

**For Questions:**

- Create an issue in the repository
- Contact the iOS team
- Review existing Bash scripts for reference
- See CONFIGURATION.md for setup help

---

## 🎉 Summary

This implementation plan has been updated to reflect the successful refactoring of the Bash scripts to be framework-agnostic. The Ruby rewrite will build upon this improved foundation, maintaining the flexible configuration system while adding enhanced UX, validation, and testing capabilities.

**Key Achievements:**

- ✅ Bash scripts now work with any iOS XCFramework project
- ✅ No hardcoded project names or paths
- ✅ Environment variable-based configuration
- ✅ Comprehensive documentation
- ✅ Production-ready for immediate use

**Next Phase:**

The Ruby implementation will enhance these capabilities with:

- Better error handling and validation
- Improved user experience
- Comprehensive testing (90%+ coverage)
- Type safety and OOP design
- Enhanced CLI with Thor framework

---

## 📄 License

Copyright © 2025 AAVN. All rights reserved.

---

**Last Updated**: December 4, 2025
**Version**: 1.0.0
**Status**: Planning Phase
