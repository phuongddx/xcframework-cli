# SPM Builds

Build XCFrameworks from Swift Packages.

---

## Quick Start

```bash
# Build with auto-detection
./bin/xckit spm build --package-dir .

# Specify targets
./bin/xckit spm build --package-dir . --targets MyLibrary MyCore

# Specify platforms
./bin/xckit spm build --package-dir . --platforms ios ios-simulator
```

---

## How It Works

### Build Flow

```
Package.swift -> Parse targets -> Build per SDK -> Create frameworks -> Combine -> XCFramework
```

1. **Parse Package.swift** - Extract targets and platforms
2. **Build per SDK** - Compile with `swift build --triple <sdk-triple>`
3. **Create frameworks** - Structure with libtool, headers, modules
4. **Combine architectures** - Use lipo for multi-arch
5. **Assemble XCFramework** - Final output

---

## Resource Bundles

SPM builds automatically handle resource bundles

### Detection

The tool looks for bundles at:
```
.build/<triple>/release/PackageName_TargetName.bundle
```

### Bundle.module Access

If a resource bundle is found, the tool generates a custom `Bundle.module` accessor

```swift
// Auto-generated
import Foundation

private class BundleFinder {}

extension BundleFinder {
  static var module: Bundle {
    Bundle(url: Bundle.main.bundleURL.appendingPathComponent("PackageName_TargetName.bundle"))
  }
}

extension Bundle {
  static var module: Bundle { BundleFinder.module }
}
```

---

## Configuration

SPM builds can use configuration files too

```yaml
spm:
  package_dir: "."
  targets: ["MyLibrary"]
  platforms: [ios, ios-simulator]
  library_evolution: true

build:
  output_dir: "build"
  configuration: "Release"
```

---

## Command Options

| Option | Description |
|-------|-------------|
| `--package-dir` | Path to Package.swift directory |
| `--targets` | Target names to build |
| `--platforms` | Platforms (ios, ios-simulator) |
| `--verbose` | Show detailed output |
| `--quiet` | Only show errors |

---

## Examples

### Basic SPM Build

```bash
./bin/xckit spm build --package-dir ~/MyPackage
```

### Multi-target Build

```bash
./bin/xckit spm build --package-dir . --targets CoreKit UIKit NetworkKit
```

### Specific Platforms

```bash
# iOS device only
./bin/xckit spm build --package-dir . --platforms ios

# iOS + Simulator
./bin/xckit spm build --package-dir . --platforms ios ios-simulator
```
