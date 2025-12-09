# XCFramework CLI

> A professional Ruby CLI tool for building XCFrameworks across all Apple platforms

[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org/)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/phuongddx/xcframework-cli)
[![Tests](https://img.shields.io/badge/tests-109%20passing-success.svg)](spec/)

**Status**: ✅ **Production Ready for iOS** | 🚧 Other platforms in development

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Command Line Mode](#command-line-mode)
  - [Configuration File Mode](#configuration-file-mode)
  - [Verbose Output](#verbose-output)
- [Configuration](#configuration)
- [Platform Support](#platform-support)
- [Requirements](#requirements)
- [Development](#development)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

---

## Features

✅ **Production-Ready iOS Support**
- iOS Device (arm64)
- iOS Simulator (arm64, x86_64)
- Complete build pipeline with validation

✅ **Real-Time Build Logs**
- Automatic formatter detection (`xcbeautify` or `xcpretty`)
- Colored, formatted xcodebuild output
- Configurable via command line or config file

✅ **Flexible Configuration**
- YAML or JSON configuration files
- Command-line arguments
- Schema validation with helpful error messages

✅ **Developer Experience**
- Clean, colored output with progress indicators
- Verbose mode for debugging
- Debug symbols (dSYM) support
- Comprehensive error messages with suggestions

✅ **Well-Tested**
- 109 unit tests passing
- Integration tests with real projects
- 68%+ code coverage

---

## Installation

### Prerequisites

- **Ruby 3.0+** - Check with `ruby --version`
- **Xcode** - With command line tools installed
- **Bundler** - Install with `gem install bundler`

### Setup

```bash
# Clone the repository
git clone https://github.com/phuongddx/xcframework-cli.git
cd xcframework-cli

# Install dependencies
bundle install

# Verify installation
./bin/xckit version
```

### Optional: Install Formatters

For beautifully formatted build output:

```bash
# Install xcbeautify (recommended)
brew install xcbeautify

# Or install xcpretty
gem install xcpretty
```

---

## Quick Start

### 1. Command Line Mode

Build an XCFramework with command-line arguments:

```bash
./bin/xckit build \
  --project MySDK.xcodeproj \
  --scheme MySDK \
  --framework-name MySDK \
  --output build \
  --platforms ios ios-simulator
```

### 2. Configuration File Mode

Create `.xcframework.yml`:

```yaml
project:
  name: MySDK
  xcode_project: MySDK.xcodeproj

frameworks:
  - name: MySDK
    scheme: MySDK
    platforms:
      - ios
      - ios-simulator
    deployment_targets:
      ios: "14.0"

build:
  output_dir: build
  clean_before_build: true
  verbose: true              # See xcodebuild logs
  use_formatter: true        # Use xcbeautify/xcpretty
```

Build with config:

```bash
./bin/xckit build --config .xcframework.yml
```

### 3. See Build Logs

Enable verbose mode to see real-time xcodebuild output:

```bash
./bin/xckit build \
  --config .xcframework.yml \
  --verbose
```

**Output:**
```
🔍 Using formatter: xcbeautify

[MySDK] Linking MySDK
[MySDK] Generating MySDK.framework.dSYM
⚠️  Warning: ...
✅ Archive Succeeded
```

---

## Usage

### Command Line Mode

```bash
./bin/xckit build [OPTIONS]
```

#### Required Options

- `--project PATH` - Path to .xcodeproj or .xcworkspace
- `--scheme NAME` - Xcode scheme name
- `--framework-name NAME` - Framework name (without .framework extension)

#### Optional Options

- `--output DIR` - Output directory (default: `build`)
- `--platforms PLATFORMS` - Space-separated list (default: `ios ios-simulator`)
- `--clean` / `--no-clean` - Clean before build (default: true)
- `--debug-symbols` / `--no-debug-symbols` - Include dSYM files (default: true)
- `--verbose` / `-v` - Show xcodebuild logs
- `--quiet` / `-q` - Suppress output

#### Example

```bash
./bin/xckit build \
  --project Example/SwiftyBeaver/SwiftyBeaver.xcodeproj \
  --scheme SwiftyBeaver-Package \
  --framework-name SwiftyBeaver \
  --output build \
  --platforms ios ios-simulator \
  --verbose
```

**Result:**
```
✅ Build completed successfully!
   XCFramework: build/SwiftyBeaver.xcframework

   Archives created:
     ✓ ios: ios - build/SwiftyBeaver-Package-iOS.xcarchive
     ✓ ios-simulator: iOS Simulator - build/SwiftyBeaver-Package-iOS-Simulator.xcarchive
```

---

### Configuration File Mode

Create a `.xcframework.yml` or `.xcframework.json` file:

```yaml
project:
  name: MySDK
  xcode_project: MySDK.xcodeproj

frameworks:
  - name: MySDK
    scheme: MySDK
    platforms:
      - ios
      - ios-simulator
    architectures:
      ios:
        - arm64
      ios-simulator:
        - arm64
        - x86_64
    deployment_targets:
      ios: "14.0"
      ios-simulator: "14.0"

build:
  output_dir: build
  clean_before_build: true
  verbose: false
  use_formatter: true
```

Then build:

```bash
./bin/xckit build --config .xcframework.yml
```

See [Configuration](#configuration) for all available options.

---

### Verbose Output

#### Enable via Command Line

```bash
./bin/xckit build --config .xcframework.yml --verbose
```

#### Enable via Config File

```yaml
build:
  verbose: true               # Enable verbose output
  use_formatter: true         # Use xcbeautify/xcpretty
```

#### What You See

With verbose mode enabled, you'll see real-time xcodebuild output:

```
🔍 Executing: xcodebuild archive -project ...
🔍 Using formatter: xcbeautify

[MySDK] Write Auxiliary File module.modulemap
[MySDK] Compiling MySDK.swift
[MySDK] Linking MySDK
[MySDK] Generating MySDK.framework.dSYM
⚠️  /path/to/file.swift:12:12: warning message
✅ Archive Succeeded

🔍 Command succeeded
✓ Archive created: build/MySDK-iOS.xcarchive
```

#### Formatter Options

```yaml
build:
  use_formatter: true          # Auto-detect xcbeautify or xcpretty
  # OR
  use_formatter: "xcbeautify"  # Force specific formatter
  # OR
  use_formatter: false         # Disable formatting (raw output)
```

**Formatter Priority:**
1. `xcbeautify` (preferred) - Modern, fast
2. `xcpretty` (fallback) - Classic formatter
3. Plain output - No formatting

---

## Configuration

### Configuration File Structure

The CLI searches for config files in this order:
1. `.xcframework.yml`
2. `.xcframework.yaml`
3. `xcframework.yml`
4. `xcframework.yaml`
5. `.xcframework.json`
6. `xcframework.json`

### Complete Configuration Example

```yaml
# Project information
project:
  name: MySDK                    # Project name
  xcode_project: MySDK.xcodeproj # Path to .xcodeproj

# Frameworks to build
frameworks:
  - name: MySDK                  # Framework name
    scheme: MySDK                # Xcode scheme
    platforms:                   # Platforms to build for
      - ios
      - ios-simulator

    # Optional: Override default architectures
    architectures:
      ios:
        - arm64
      ios-simulator:
        - arm64
        - x86_64

    # Optional: Override default deployment targets
    deployment_targets:
      ios: "14.0"
      ios-simulator: "14.0"

    # Optional: Resource bundles (not yet implemented)
    # resource_bundles:
    #   - MySDKResources
    # resource_module: MySDK

# Build settings
build:
  output_dir: build              # Output directory
  xcframework_output: MySDK.xcframework
  clean_before_build: true       # Clean before build
  parallel_builds: false         # Parallel builds (not yet implemented)
  verbose: false                 # Show xcodebuild logs
  use_formatter: true            # Use xcbeautify/xcpretty

# Publishing (not yet implemented)
# publishing:
#   artifactory_url: https://artifactory.example.com
#   package_scope: com.example
#   version: 1.0.0
```

See [`config/examples/`](config/examples/) for more examples.

---

## Platform Support

| Platform | Architectures | Status |
|----------|---------------|--------|
| **iOS Device** | arm64 | ✅ **Production Ready** |
| **iOS Simulator** | arm64, x86_64 | ✅ **Production Ready** |
| macOS | arm64, x86_64 | 🚧 Planned (Phase 2) |
| Mac Catalyst | arm64, x86_64 | 🚧 Planned (Phase 2) |
| tvOS Device | arm64 | 🚧 Planned (Phase 2) |
| tvOS Simulator | arm64, x86_64 | 🚧 Planned (Phase 2) |
| watchOS Device | arm64_32, arm64 | 🚧 Planned (Phase 2) |
| watchOS Simulator | arm64, x86_64 | 🚧 Planned (Phase 2) |
| visionOS Device | arm64 | 🚧 Planned (Phase 2) |
| visionOS Simulator | arm64 | 🚧 Planned (Phase 2) |

**Current Focus**: iOS platforms are fully implemented and tested.
**Roadmap**: Other platforms will follow the same architecture pattern.

---

## Requirements

### System Requirements

- **macOS** 11.0 or later
- **Xcode** 13.0 or later (with command line tools)
- **Ruby** 3.0 or later

### Dependencies

**Runtime:**
- `thor` ~> 1.3 - CLI framework
- `colorize` ~> 1.1 - Terminal colors
- `dry-validation` ~> 1.10 - Schema validation
- `tty-prompt` ~> 0.23 - Interactive prompts
- `tty-spinner` ~> 0.9 - Progress indicators

**Development:**
- `rspec` ~> 3.12 - Testing framework
- `rubocop` ~> 1.50 - Code linting
- `simplecov` ~> 0.22 - Code coverage
- `pry` ~> 0.14 - Debugging

---

## Development

### Running Tests

```bash
# Run all tests with coverage
bundle exec rake spec

# Run tests without coverage requirement
bundle exec rake test

# Run specific test file
bundle exec rspec spec/unit/builder/orchestrator_spec.rb

# Run integration tests (requires example project)
RUN_INTEGRATION_TESTS=1 bundle exec rspec spec/integration/
```

### Code Quality

```bash
# Lint code
bundle exec rake rubocop

# Auto-fix linting issues
bundle exec rake lint_fix

# Check coverage
open coverage/index.html
```

### Interactive Console

```bash
# Open Pry console with gem loaded
bundle exec rake console

# Example usage:
> Platform::Registry.all_platforms
> Config::Loader.load(path: 'config/examples/basic.yml')
```

### Project Structure

```
lib/xcframework_cli/
├── cli/
│   ├── runner.rb              # Thor CLI entry point
│   └── commands/
│       └── build.rb           # Build command
├── builder/
│   ├── orchestrator.rb        # Build pipeline coordinator
│   ├── cleaner.rb             # Artifact cleanup
│   ├── archiver.rb            # Platform archive creation
│   └── xcframework.rb         # XCFramework assembly
├── config/
│   ├── loader.rb              # Config file loader
│   ├── schema.rb              # Validation schema
│   └── defaults.rb            # Default values
├── platform/
│   ├── base.rb                # Platform abstract class
│   ├── registry.rb            # Platform factory
│   ├── ios.rb                 # iOS implementation
│   └── ios_simulator.rb       # iOS Simulator implementation
├── xcodebuild/
│   ├── wrapper.rb             # xcodebuild command wrapper
│   ├── formatter.rb           # Output formatting
│   └── result.rb              # Command result object
└── utils/
    ├── logger.rb              # Colored logging
    └── spinner.rb             # Progress indicators
```

---

## Architecture

### Build Pipeline

```
1. Clean (optional)
   ↓
2. Archive (per platform)
   ├── iOS Device → .xcarchive
   └── iOS Simulator → .xcarchive
   ↓
3. Create XCFramework
   └── .xcframework (with dSYMs)
```

### Platform Abstraction

All platforms inherit from `Platform::Base` with standardized interface:

```ruby
class Platform::Base
  # Class methods
  def self.platform_name          # "iOS"
  def self.platform_identifier    # "ios"
  def self.sdk_name               # "iphoneos"
  def self.destination            # "generic/platform=iOS"
  def self.valid_architectures    # ["arm64"]
  def self.default_deployment_target  # "14.0"
end
```

See [`ARCHITECTURE_OVERVIEW.md`](docs/ARCHITECTURE_OVERVIEW.md) for detailed diagrams.

---

## Contributing

We welcome contributions! Here's how:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Add tests** for new functionality
4. **Ensure** tests pass (`bundle exec rake spec`)
5. **Lint** code (`bundle exec rake rubocop`)
6. **Commit** changes (`git commit -m 'feat: add amazing feature'`)
7. **Push** to branch (`git push origin feature/amazing-feature`)
8. **Open** a Pull Request

### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test changes
- `refactor:` - Code refactoring
- `chore:` - Maintenance tasks

---

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - AI assistant guide for development
- **[Architecture Overview](docs/ARCHITECTURE_OVERVIEW.md)** - Detailed architecture
- **[Phase D Summary](docs/PHASE_D_SUMMARY.md)** - Integration testing summary
- **[Implementation Progress](docs/IMPLEMENTATION_PROGRESS.md)** - Development roadmap
- **[Changelog](docs/CHANGELOG.md)** - Version history
- **[All Documentation](docs/)** - Complete documentation index

---

## License

Copyright © 2025 AAVN. All rights reserved.

---

## Team

**Project Lead**: Phuong Doan Duy
**Organization**: AAVN
**Repository**: [github.com/phuongddx/xcframework-cli](https://github.com/phuongddx/xcframework-cli)

---

## Support

- **Issues**: [GitHub Issues](https://github.com/phuongddx/xcframework-cli/issues)
- **Discussions**: [GitHub Discussions](https://github.com/phuongddx/xcframework-cli/discussions)

---

**Last Updated**: December 6, 2025
**Version**: 0.1.0
**Status**: ✅ Production Ready for iOS
