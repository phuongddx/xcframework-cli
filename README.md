# XCFramework CLI

> Build XCFrameworks from Xcode projects or Swift Packages

[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org/)
[![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)](https://github.com/phuongddx/xcframework-cli)
[![Tests](https://img.shields.io/badge/tests-109%20passing-success.svg)](spec/)
[![License](https://img.shields.io/badge/license-AAVN-lightgrey.svg)](#license)

**Status**: ✅ Production Ready for iOS | 🚧 Other platforms in development

## Features

- ✅ Build from Xcode projects (`.xcodeproj`/`.xcworkspace`)
- ✅ Build from Swift Packages (`Package.swift`)
- ✅ iOS + iOS Simulator support (arm64, x86_64)
- ✅ Resource bundles with custom `Bundle.module`
- ✅ YAML/JSON configuration files
- ✅ Colored output with `xcbeautify`/`xcpretty`
- 🚧 macOS, tvOS, watchOS, visionOS (planned)

---

## Setup

**Requirements:**
- Ruby 3.0+
- Xcode with command line tools
- Bundler (`gem install bundler`)

**Install:**

```bash
git clone https://github.com/phuongddx/xcframework-cli.git
cd xcframework-cli
bundle install

# Verify
./bin/xckit version
```

**Optional - Better output formatting:**

```bash
brew install xcbeautify  # or: gem install xcpretty
```

---

## Quick Start

**From Xcode Project:**

```bash
./bin/xckit build \
  --project MySDK.xcodeproj \
  --scheme MySDK \
  --framework-name MySDK \
  --platforms ios ios-simulator
```

**From Swift Package:**

```bash
./bin/xckit spm build \
  --package-dir . \
  --platforms ios ios-simulator \
  --output-dir build
```

**With Config File:**

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
  configuration: Release
```

Then:

```bash
./bin/xckit build --config .xcframework.yml
```

---

## Configuration

### Xcode Project Config

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
  configuration: Release
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
```

### Swift Package Config

```yaml
spm:
  package_dir: "."
  targets: [MyLibrary]
  platforms: [ios, ios-simulator]

build:
  output_dir: "./build"
  configuration: "Release"
```

See [`config/examples/`](config/examples/) for more examples.

---

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Contributing Guide](docs/CONTRIBUTING.md)
- [Changelog](docs/CHANGELOG.md)

---

## License

Copyright © 2025 AAVN. All rights reserved.

**Repository**: [github.com/phuongddx/xcframework-cli](https://github.com/phuongddx/xcframework-cli)
