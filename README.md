# XCFramework CLI

> A professional Ruby CLI tool for building XCFrameworks across all Apple platforms

[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org/)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/phuongddx/xcframework-cli)
[![Tests](https://img.shields.io/badge/tests-109%20passing-success.svg)](spec/)
[![Coverage](https://img.shields.io/badge/coverage-68%25-yellow.svg)](coverage/)
[![License](https://img.shields.io/badge/license-AAVN-lightgrey.svg)](#license)

**Status**: ✅ **Production Ready for iOS** | 🚧 Other platforms in development

---

## 📚 Documentation

- **[Architecture Guide](docs/ARCHITECTURE.md)** - High-level architecture overview
- **[Configuration Guide](docs/CONFIGURATION.md)** - Configuration options
- **[Resource Bundle Implementation](docs/RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md)** - SPM resource bundle support
- **[Changelog](docs/CHANGELOG.md)** - Version history
- **[Contributing Guide](docs/CONTRIBUTING.md)** - Development setup and guidelines

---

## ✨ Features

| Feature | Status | Description |
|---------|--------|-------------|
| **Xcode Projects** | ✅ | Build from `.xcodeproj`/`.xcworkspace` with schemes |
| **Swift Packages** | ✅ | Build from `Package.swift` with multi-target support |
| **Resource Bundles** | ✅ | Automatic bundle handling with custom `Bundle.module` |
| **iOS Platform** | ✅ | Device (arm64) + Simulator (arm64, x86_64) |
| **Other Platforms** | 🚧 | macOS, tvOS, watchOS, visionOS, Catalyst (planned) |
| **Beautiful Output** | ✅ | Colored logs with `xcbeautify`/`xcpretty` support |
| **Configuration Files** | ✅ | YAML/JSON with validation and smart defaults |
| **Debug Symbols** | ✅ | dSYM files included in XCFrameworks |
| **109 Unit Tests** | ✅ | 68%+ code coverage, integration tested |

---

## 📦 Installation

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

## ⚡ Quick Start

### Build from Xcode Project

```bash
./bin/xckit build \
  --project MySDK.xcodeproj \
  --scheme MySDK \
  --framework-name MySDK \
  --platforms ios ios-simulator
```

### Build from Swift Package

```bash
./bin/xckit spm build \
  --package-dir . \
  --platforms ios ios-simulator \
  --output-dir build
```

### Build with Configuration File

Create `.xcframework.yml`:

```yaml
project:
  name: MySDK
  xcode_project: MySDK.xcodeproj

frameworks:
  - name: MySDK
    scheme: MySDK
    platforms: [ios, ios-simulator]

build:
  output_dir: build
  verbose: true
```

Then build:

```bash
./bin/xckit build --config .xcframework.yml
```

---

## 🚀 Usage

### Commands

```bash
xckit COMMAND [OPTIONS]

Commands:
  build       Build XCFramework from Xcode project
  spm build   Build XCFramework from Swift Package
  version     Display version information
  help        Display help message

Global Options:
  -v, --verbose    Enable verbose output
  -q, --quiet      Suppress output
```

### Xcode Project Build

```bash
./bin/xckit build [OPTIONS]
```

**Required:**
- `--project PATH` - Path to `.xcodeproj` or `.xcworkspace`
- `--scheme NAME` - Xcode scheme name
- `--framework-name NAME` - Framework name

**Optional:**
- `--output DIR` - Output directory (default: `build`)
- `--platforms PLATFORMS` - Platforms (default: `ios ios-simulator`)
- `--config FILE` - Configuration file path
- `--verbose` / `-v` - Show xcodebuild logs
- `--clean` - Clean before build (default: true)

### Swift Package Build

```bash
./bin/xckit spm build [TARGET...] [OPTIONS]
```

**Optional:**
- `--package-dir PATH` - Package directory (default: `.`)
- `--platforms PLATFORMS` - Platforms (default: `ios ios-simulator`)
- `--output-dir DIR` - Output directory (default: `./build`)
- `--configuration CONFIG` - Build config: `debug`/`release` (default: `release`)
- `--library-evolution` - Enable library evolution (default: true)
- `--config FILE` - Configuration file path
- `--verbose` / `-v` - Show build logs

**Examples:**

```bash
# Build all library targets
./bin/xckit spm build

# Build specific targets
./bin/xckit spm build MyLibrary AnotherLibrary

# With config file
./bin/xckit spm build --config spm.yml

# Verbose output
./bin/xckit spm build --verbose
```

**Output:**
```
✓ Build successful!

Created XCFrameworks:
  • ./build/MyLibrary.xcframework
  • ./build/AnotherLibrary.xcframework
```

---

## ⚙️ Configuration

Configuration files are searched in this order:
1. `.xcframework.yml` / `.xcframework.yaml`
2. `xcframework.yml` / `xcframework.yaml`
3. `.xcframework.json` / `xcframework.json`

### Xcode Project Configuration

```yaml
# Project information
project:
  name: MySDK
  xcode_project: MySDK.xcodeproj

# Frameworks to build
frameworks:
  - name: MySDK
    scheme: MySDK
    platforms: [ios, ios-simulator]

    # Optional: Override architectures
    architectures:
      ios: [arm64]
      ios-simulator: [arm64, x86_64]

    # Optional: Override deployment targets
    deployment_targets:
      ios: "14.0"
      ios-simulator: "14.0"

# Build settings
build:
  output_dir: build
  configuration: Release          # or Debug
  clean_before_build: true
  verbose: false
  use_formatter: true             # xcbeautify/xcpretty

  # Custom xcodebuild settings
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
    ENABLE_BITCODE: "NO"
```

### Swift Package Configuration

```yaml
spm:
  package_dir: "."
  targets: [MyLibrary]            # or omit for auto-detect
  platforms: [ios, ios-simulator]
  library_evolution: true

build:
  output_dir: "./build"
  configuration: "Release"
  verbose: true
```

### Common Build Settings

**Fix module interface errors:**
```yaml
build_settings:
  OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
```

**Exclude Intel simulator (faster builds):**
```yaml
build_settings:
  EXCLUDED_ARCHS: "x86_64"
```

**Disable bitcode:**
```yaml
build_settings:
  ENABLE_BITCODE: "NO"
```

See [`config/examples/`](config/examples/) for more examples.

---

## 🏗️ Architecture

XCFramework CLI uses a modular, pipeline-based architecture:

```
CLI (Thor) → Orchestrator → Builders → Apple Tools → .xcframework
                             ├── Xcode: Archiver → XCFramework
                             └── SPM: Swift Builder → Framework Slices → XCFramework
```

**Build Flows:**

| Source | Flow |
|--------|------|
| **Xcode** | Config → Clean → Archive (per platform) → Create XCFramework |
| **SPM** | Package.swift → swift build → Framework Slices → Resource Bundles → XCFramework |

For detailed architecture diagrams and module descriptions, see **[Architecture Guide](docs/ARCHITECTURE.md)**.

---

## 🎯 Platform Support

| Platform | Architectures | Status |
|----------|---------------|--------|
| **iOS Device** | arm64 | ✅ Production Ready |
| **iOS Simulator** | arm64, x86_64 | ✅ Production Ready |
| macOS | arm64, x86_64 | 🚧 Planned |
| Mac Catalyst | arm64, x86_64 | 🚧 Planned |
| tvOS | arm64 | 🚧 Planned |
| tvOS Simulator | arm64, x86_64 | 🚧 Planned |
| watchOS | arm64_32, arm64 | 🚧 Planned |
| watchOS Simulator | arm64, x86_64 | 🚧 Planned |
| visionOS | arm64 | 🚧 Planned |
| visionOS Simulator | arm64 | 🚧 Planned |

**Current Focus**: iOS platforms are fully implemented and tested.

---

## 🔧 Requirements

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

---

## 🧪 Development

### Quick Commands

```bash
# Run all tests with coverage
bundle exec rake spec

# Run tests without coverage requirement
bundle exec rake test

# Lint code
bundle exec rake rubocop

# Auto-fix linting issues
bundle exec rake lint_fix

# Interactive console
bundle exec rake console
```

For detailed development setup, testing conventions, and contribution guidelines, see **[Contributing Guide](docs/CONTRIBUTING.md)**.

---

## 🤝 Contributing

We welcome contributions! Please see **[CONTRIBUTING.md](docs/CONTRIBUTING.md)** for:

- Development setup and workflow
- Testing conventions and coverage requirements
- Code style guidelines
- Commit message conventions
- Pull request process

### Quick Contribution Steps

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Add tests for new functionality
4. Ensure tests pass (`bundle exec rake spec`)
5. Lint code (`bundle exec rake rubocop`)
6. Commit changes (`git commit -m 'feat: add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

---

## 📄 License

Copyright © 2025 AAVN. All rights reserved.

---

## 👥 Team

**Project Lead**: Phuong Doan Duy
**Organization**: AAVN
**Repository**: [github.com/phuongddx/xcframework-cli](https://github.com/phuongddx/xcframework-cli)

---

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/phuongddx/xcframework-cli/issues)
- **Discussions**: [GitHub Discussions](https://github.com/phuongddx/xcframework-cli/discussions)
- **Documentation**: [docs/](docs/)

---

**Last Updated**: December 9, 2025
**Version**: 0.1.0
**Status**: ✅ Production Ready for iOS
