# XCFramework CLI

> Build XCFrameworks from Xcode projects or Swift Packages across Apple platforms

[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org/)
[![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)](https://github.com/phuongddx/xcframework-cli)
[![Tests](https://img.shields.io/badge/tests-280%2B%20passing-success.svg)](spec/)
[![License](https://img.shields.io/badge/license-AAVN-lightgrey.svg)](#license)

**Status**: ✅ Production Ready for iOS | 🚧 Other platforms in development

## What is XCFramework CLI?

XCFramework CLI is a Ruby gem that automates XCFramework creation from Xcode projects and Swift Packages. It handles the complexity of multi-platform builds, custom configurations, and resource management through simple configuration files and CLI commands.

Perfect for:
- Publishing framework libraries across Apple platforms
- Distributing SDKs with resource bundles (fonts, images, themes)
- Automating CI/CD pipelines for framework distribution
- Managing complex build settings per platform

## Features

- ✅ **Xcode Projects** - Build from `.xcodeproj` or `.xcworkspace`
- ✅ **Swift Packages** - Build from `Package.swift`
- ✅ **iOS Support** - iOS device (arm64) and Simulator (arm64, x86_64)
- ✅ **Resource Bundles** - Fonts, images, JSON themes with `Bundle.module`
- ✅ **Configuration Files** - YAML/JSON with validation
- ✅ **Custom Build Settings** - Override Xcode defaults per framework
- ✅ **Beautiful Output** - Colored build logs with `xcbeautify`/`xcpretty`
- ✅ **Error Handling** - Helpful suggestions for common issues
- 🚧 **Platform Expansion** - macOS, tvOS, watchOS, visionOS, Catalyst (Phase 2)

## Quick Start

### 1. Install

```bash
git clone https://github.com/phuongddx/xcframework-cli.git
cd xcframework-cli
bundle install

# Verify installation
./bin/xckit version
```

**Requirements:**
- Ruby 3.0+
- Xcode 12+ with command-line tools
- Bundler (`gem install bundler`)

**Optional (better output):**
```bash
brew install xcbeautify  # Xcode build formatter
```

### 2. Create Configuration

Create `.xcframework.yml` in your project root:

```yaml
project:
  name: MySDK
  xcode_project: MySDK.xcodeproj

frameworks:
  - name: MySDK
    scheme: MySDK
    platforms: [ios, ios-simulator]
    deployment_targets:
      ios: "14.0"

build:
  output_dir: build
  configuration: Release
  clean_before_build: true
```

### 3. Build XCFramework

```bash
./bin/xckit build --config .xcframework.yml
```

Output: `build/MySDK.xcframework/` ready for distribution

## Usage Examples

### Command-Line Build

```bash
./bin/xckit build \
  --project MySDK.xcodeproj \
  --scheme MySDK \
  --framework-name MySDK \
  --platforms ios ios-simulator
```

### SPM Package Build

```bash
./bin/xckit spm build \
  --package-dir . \
  --platforms ios ios-simulator \
  --output-dir build
```

### Configuration-Driven Build

```bash
./bin/xckit build --config .xcframework.yml --verbose
```

### Initialize Configuration (Interactive)

```bash
./bin/xckit init
# Follow prompts to generate .xcframework.yml
```

## Configuration Guide

### Xcode Project

```yaml
project:
  name: MyFramework
  xcode_project: MyFramework.xcodeproj

frameworks:
  - name: MyFramework
    scheme: MyFramework
    platforms: [ios, ios-simulator]
    deployment_targets:
      ios: "14.0"
    architectures:
      ios: [arm64]
      ios-simulator: [arm64, x86_64]

build:
  output_dir: build
  configuration: Release
  clean_before_build: true
  verbose: false
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
```

### Swift Package

```yaml
spm:
  package_dir: "."
  targets: [MyLibrary]
  platforms: [ios, ios-simulator]
  library_evolution: true
  version: "14.0"

build:
  output_dir: "./build"
  configuration: Release
```

See `config/examples/` for additional examples and use cases.

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture Guide](docs/system-architecture.md) | Detailed system design and data flows |
| [Configuration Reference](docs/CONFIGURATION.md) | Complete config options and examples |
| [Code Standards](docs/code-standards.md) | Development conventions and patterns |
| [Project Roadmap](docs/project-roadmap.md) | Current status and planned features |
| [Contributing Guide](docs/CONTRIBUTING.md) | How to contribute and extend |

## Project Status

**Phase 1 (Current): Foundation** ✅
- iOS and iOS Simulator platforms fully implemented
- Xcode project and SPM builds working
- 280+ test cases with 80% coverage
- Configuration validation and error handling
- Resource bundle support (in progress)

**Phase 2 (Planned): Platform Expansion**
- macOS, tvOS, watchOS, visionOS, Catalyst support
- Template-based resource compilation
- Advanced caching and optimization

## Real-World Example

See `Example/epost-ios-theme-ui/` for a production-ready UIKit framework using XCFramework CLI. Demonstrates:
- Complex resource management (fonts, images, themes)
- Custom build settings and workarounds
- Multi-platform configuration
- Integration with CI/CD

## Help & Support

```bash
# Show all commands
./bin/xckit --help

# Show specific command help
./bin/xckit build --help

# Verbose output for debugging
./bin/xckit build --config .xcframework.yml -v
```

## Common Issues

**Module interface verification error:**
```yaml
build_settings:
  OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
```

**x86_64 simulator build failure (Apple Silicon):**
```yaml
build_settings:
  EXCLUDED_ARCHS: "x86_64"
```

**Framework not found in archive:**
Check that scheme name matches framework name and scheme builds the target.

## License

Copyright © 2025 AAVN. All rights reserved.

**Repository**: [github.com/phuongddx/xcframework-cli](https://github.com/phuongddx/xcframework-cli)
