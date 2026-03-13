# Welcome to XCFramework CLI

A Ruby gem for building XCFrameworks across all Apple platforms.

## Features

- **Multi-platform support**: iOS, iOS Simulator, macOS, tvOS, watchOS, visionOS, Catalyst
- **Simple configuration**: YAML or JSON configuration files
- **Automated pipeline**: Clean, archive, and assemble in one command
- **Flexible build settings**: Custom xcodebuild flags support

## Quick Start

Install the gem:

```bash
gem install xcframework-cli
```

Create a configuration file:

```yaml
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"

frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms: [ios, ios-simulator]

build:
  configuration: "Release"
```

Build your framework:

```bash
xcframework build
```

## Documentation

- [Getting Started](/getting-started)
- [Configuration Guide](/configuration)
- [Platforms](/platforms)
- [API Reference](/api-reference)
