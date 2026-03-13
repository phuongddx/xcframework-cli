# Configuration Guide

XCFramework CLI supports flexible configuration through YAML or JSON files.

---

## Configuration Files

The Config files are searched in this order:
1. `.xcframework.yml`
2. `.xcframework.yaml`
3. `xcframework.yml`
4. `xcframework.yaml`
5. `.xcframework.json`
6. `xcframework.json`

---

## Basic Structure

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
  output_dir: "build"
  clean_before_build: true
  verbose: false
```

---

## Full Configuration Example

```yaml
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"
  # Optional: workspace
  workspace: "MyProject.xcworkspace"

frameworks:
  - name: "CoreSDK"
    scheme: "CoreSDK"
    platforms: [ios, ios-simulator]
    # Optional: custom architectures per platform
    architectures:
      ios: [arm64]
      ios-simulator: [arm64, x86_64]
    # Optional: deployment targets
    deployment_targets:
      ios: "14.0"
      ios-simulator: "14.0"

  - name: "NetworkSDK"
    scheme: "NetworkSDK"
    platforms: [ios, ios-simulator]

build:
  configuration: "Release"
  output_dir: "build"
  clean_before_build: true
  verbose: false
  # Custom build settings passed to xcodebuild
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
    ENABLE_BITCODE: "NO"

# SPM-only configuration
spm:
  package_dir: "./"
  targets: ["MyTarget", "AnotherTarget"]
  platforms: [ios, ios-simulator]
  library_evolution: true
```

---

## Configuration Reference

### Project Section (Xcode Projects)

| Field | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | Yes | Project/framework name |
| `xcode_project` | string | Yes* | Path to .xcodeproj file |
| `workspace` | string | No | Path to .xcworkspace file |

*Either `xcode_project` or `spm` is required

### Frameworks Section

| Field | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | Yes | Framework name |
| `scheme` | string | Yes | Xcode scheme to build |
| `platforms` | array | Yes | List of platforms to build for |
| `architectures` | object | No | Override archs per platform |
| `deployment_targets` | object | No | Override min OS version |

### Build Section

| Field | Type | Default | Description |
|------|------|---------|-------------|
| `configuration` | string | "Release" | Build configuration (Debug/Release) |
| `output_dir` | string | "build" | Output directory for artifacts |
| `clean_before_build` | boolean | false | Clean old artifacts before building |
| `verbose` | boolean | false | Enable verbose output |
| `build_settings` | object | {} | Custom xcodebuild settings |

### SPM Section (Swift Packages)

| Field | Type | Required | Description |
|------|------|----------|-------------|
| `package_dir` | string | Yes | Package root directory |
| `targets` | array | No | Targets to build (inferred if not specified) |
| `platforms` | array | Yes | Platforms to build for |
| `library_evolution` | boolean | true | Enable library evolution support |

---

## Platform Identifiers

Currently supported:
- `ios` - iOS Device (arm64)
- `ios-simulator` - iOS Simulator (arm64, x86_64)

Schema defined (Phase 2):
- `macos`
- `tvos`, `tvos-simulator`
- `watchos`, `watchos-simulator`
- `visionos`, `visionos-simulator`
- `catalyst`

---

## Custom Build Settings

Add custom xcodebuild flags via `build.build_settings`:

### Common Use Cases

#### Fix Module Interface Errors
```yaml
build:
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
```

#### Exclude x86_64 Simulator
```yaml
build:
  build_settings:
    EXCLUDED_ARCHS: "x86_64"
```

#### Disable Bitcode
```yaml
build:
  build_settings:
    ENABLE_BITCODE: "NO"
```

---

## CLI Overrides

Most configuration options can be overridden via CLI:

```bash
# Override output directory
./bin/xckit build --output-dir ./dist

# Override configuration
./bin/xckit build --configuration Debug

# Enable verbose output
./bin/xckit build --verbose
```
