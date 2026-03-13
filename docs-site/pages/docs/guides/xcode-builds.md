# Xcode Project Builds

Build XCFrameworks from Xcode projects.

---

## Quick Start

```bash
# Using config file
./bin/xckit build --config .xcframework.yml

# With verbose output
./bin/xckit build --config .xcframework.yml --verbose

# Clean before build
./bin/xckit build --config .xcframework.yml --clean
```

---

## Build Flow

```
Config -> Validate -> Clean (optional) -> Archive per platform -> Create XCFramework
```

1. **Load Config** - Parse YAML/JSON
2. **Validate** - Check schema
3. **Clean** - Remove old artifacts (optional)
4. **Archive** - Create .xcarchive per platform
5. **Assemble** - Create final .xcframework

---

## Configuration

### Minimal Config

```yaml
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"

frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms: [ios, ios-simulator]
```

### Full Config

```yaml
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"
  workspace: "MyProject.xcworkspace"  # If using pods

frameworks:
  - name: "CoreSDK"
    scheme: "CoreSDK"
    platforms: [ios, ios-simulator]
    architectures:
      ios: [arm64]
      ios-simulator: [arm64, x86_64]
    deployment_targets:
      ios: "14.0"
      ios-simulator: "15.0"

  - name: "NetworkSDK"
    scheme: "NetworkSDK"
    platforms: [ios, ios-simulator]

build:
  configuration: "Release"
  output_dir: "build"
  clean_before_build: true
  verbose: false
```

---

## Command Options

| Option | Description |
|-------|-------------|
| `--config` | Path to config file |
| `--clean` | Clean before build |
| `--verbose` | Show detailed output |
| `--quiet` | Only show errors |
| `--output-dir` | Override output directory |

---

## Examples

### Basic Build

```bash
./bin/xckit build --config .xcframework.yml
```

### With Workspace

```yaml
project:
  name: "MyProject"
  workspace: "MyProject.xcworkspace"  # Uses CocoaPods workspace
```

```bash
./bin/xckit build --config .xcframework.yml
```

### Multiple Frameworks

```yaml
frameworks:
  - name: "CoreSDK"
    scheme: "CoreSDK"
    platforms: [ios, ios-simulator]
  - name: "UISDK"
    scheme: "UISDK"
    platforms: [ios, ios-simulator]
```

---

## Output

Successful builds produce

```
build/
  CoreSDK.xcframework/
    Info.plist
    ios-arm64/
      CoreSDK.framework/
    ios-arm64-x86_64-simulator/
      CoreSDK.framework/
    ...
```
