# Example Projects Analysis Report

**Date:** February 15, 2026  
**Scope:** Analyzing Example/ directory focusing on source code, configurations, and integration patterns  
**Directories Analyzed:**
- `/Users/ddphuong/Projects/xcframework-cli/Example/epost-ios-theme-ui/`
- `/Users/ddphuong/Projects/xcframework-cli/Example/SwiftyBeaver/`

---

## Executive Summary

Two example projects demonstrate XCFramework CLI usage:

1. **epost-ios-theme-ui**: A complex UIKit framework with XCFramework build configuration
2. **SwiftyBeaver**: A logging library used as SPM dependency

The epost-ios-theme-ui project serves as the primary integration test and real-world use case. SwiftyBeaver is included as a dependency but represents a separate, well-established Swift Package.

---

## 1. Example Projects Overview

### 1.1 epost-ios-theme-ui

**Purpose:** Reusable UI library for iOS applications with standardized components, typography, and theme management.

**Key Details:**
- **Language:** Swift 5.10
- **Target:** iOS 15.0+ (deployment target iOS 16.0 in config)
- **Type:** UIKit framework
- **Build System:** Xcode Project + Swift Package Manager
- **Distribution:** XCFramework (binary) + SPM
- **Author:** Phuong Doan Duy (AAVN team)

**Core Components:**
- **Grid System:** Standardized spacing (Spacing.unit = 8px, multiplier-based)
- **Typography:** Frutiger Neue family with structured font weights/sizes
- **UI Components:**
  - ThemeButton (customizable, size/style/appearance options)
  - ThemeTextField (multiple states, backgrounds, decorations)
  - ThemeToggle (styled toggle switch)
  - ThemeStandardTabs (custom tab navigation)
- **Theme System:** JSON-based theme management with brand colors
- **Extensions:** SwifterSwift (500+ native extensions), FontBlaster, Then, SwiftTheme
- **Dependencies:** AlignedCollectionViewFlowLayout

**Repository Structure:**
```
epost-ios-theme-ui/
├── .xcframework.yml          # XCFramework build config (primary)
├── spm.yml                    # SPM build config (alternative)
├── Package.swift              # Swift Package definition
├── Package.resolved           # SPM lock file
├── Makefile                   # Build automation targets
├── Gemfile                    # Ruby dependencies
├── swiftgen.yml               # Asset/code generation config
├── ios_theme_ui/              # Main framework source
│   ├── Classes/
│   │   ├── Extensions/        # UIKit/Swift extensions
│   │   ├── Libraries/         # Third-party libs (SwifterSwift, SwiftTheme, XCoordinator)
│   │   └── Theme/             # Component + color + foundation
│   └── Resources/             # Assets, fonts, themes (JSON)
├── Showcase/                  # Demo/showcase target
├── scripts/
│   ├── build-xcframework.sh   # Shell script for XCFramework build
│   └── README.md              # Build documentation
├── .github/                   # GitHub CI/CD workflows
├── .swiftlint.yml             # SwiftLint config
├── .swiftformat               # SwiftFormat config
└── CLAUDE.md                  # Development guidelines
```

**Real-World Use Case:**
- Production UI framework with 100+ component variations
- Complex theme/styling system demonstrating advanced XCFramework usage
- Resource bundle management (fonts, images, theme JSON files)
- Integration with Swift Package Manager and CocoaPods
- Uses custom build settings workaround for module interface issues

### 1.2 SwiftyBeaver

**Purpose:** Colored, lightweight logging for Swift with console, file, and cloud destination support.

**Key Details:**
- **Language:** Swift 5.0+
- **Type:** Standalone logging library
- **Distribution:** Swift Package Manager
- **Status:** Mature, external dependency
- **Repository:** github.com/SwiftyBeaver/SwiftyBeaver

**Repository Structure:**
```
SwiftyBeaver/
├── Package.swift              # Swift Package definition
├── Sources/                   # Core logging implementation
│   ├── SwiftyBeaver.swift
│   ├── BaseDestination.swift
│   ├── ConsoleDestination.swift
│   ├── FileDestination.swift
│   ├── GoogleCloudDestination.swift
│   ├── Filter.swift
│   ├── Extensions.swift
│   └── FilterValidator.swift
├── Tests/                     # Test suite
├── SwiftyBeaver.xcodeproj     # Xcode project
├── SwiftyBeaver.podspec       # CocoaPods spec
├── .swiftlint.yml             # SwiftLint config
├── Dockerfile                 # Docker build support
├── test_in_docker.sh          # Docker testing script
└── README.md                  # Documentation
```

**Usage Pattern:**
Included in epost-ios-theme-ui's Package.swift as a dependency for logging within the framework. Not directly related to XCFramework CLI, but demonstrates dependency management in Swift packages.

---

## 2. Configuration Files Analysis

### 2.1 XCFramework Configuration (.xcframework.yml)

**Location:** `/Users/ddphuong/Projects/xcframework-cli/Example/epost-ios-theme-ui/.xcframework.yml`

```yaml
project:
  name: ios_theme_ui
  xcode_project: epost-ios-theme-ui.xcodeproj

frameworks:
  - name: ios_theme_ui
    scheme: ios_theme_ui
    platforms:
      - ios
    deployment_targets:
      ios: "16.0"

build:
  output_dir: build
  clean_before_build: true
  configuration: Release
  verbose: true
  use_formatter: true
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
```

**Configuration Patterns:**
- Single framework per project
- iOS device and simulator in single platform config
- Release configuration for distribution
- Custom build settings for workarounds (module interface issues)
- Excluded x86_64 simulator architecture (Apple Silicon optimization)
- Output directory: `build/`

### 2.2 SPM Configuration (spm.yml)

**Location:** `/Users/ddphuong/Projects/xcframework-cli/Example/epost-ios-theme-ui/spm.yml`

```yaml
spm:
  package_dir: "."
  targets: ["ios_theme_ui"]
  platforms: [ios, ios-simulator]
  library_evolution: true
  version: "16.0"

build:
  output_dir: "./build"
  configuration: "Release"
  verbose: true
```

**Configuration Patterns:**
- SPM package with library evolution enabled (for ABI stability)
- Both iOS and simulator targets
- Same output directory as Xcode config
- Simpler than Xcode config, focused on SPM specifics

### 2.3 Swift Package Definition (Package.swift)

**epost-ios-theme-ui:**
- Minimum Swift: 5.10
- Platform: iOS 16+
- Products:
  - ios_theme_ui library
  - theme-ui-showcase library (demo)
- Dependencies: AlignedCollectionViewFlowLayout
- Resources: Processes `Resources/` directory (fonts, images, themes)

**SwiftyBeaver:**
- Minimum Swift: 5.0
- Products: SwiftyBeaver library
- No external dependencies
- Comprehensive test target

---

## 3. Build Configuration & Patterns

### 3.1 Makefile Targets (epost-ios-theme-ui)

**File:** `/Users/ddphuong/Projects/xcframework-cli/Example/epost-ios-theme-ui/Makefile`

Available targets:
- `make build` - Build for iOS Simulator (Debug, uses xcbeautify)
- `make lint` - Run SwiftLint checks
- `make lint-fix` - Auto-fix SwiftLint violations
- `make format` - Run SwiftFormat
- `make format-check` - Check formatting without modifying
- `make xcframework-project` - Build XCFramework via shell script
- `make clean-xcframework` - Clean build artifacts

**Build Configuration Details:**
- Uses `iPhone 17 Pro` simulator
- Derived data path: `.build`
- Configuration: Debug for development, Release for XCFramework

### 3.2 Shell Script Build (build-xcframework.sh)

**Purpose:** Automate XCFramework generation from Xcode project

**Build Process:**
1. Clean previous artifacts
2. Archive for iOS Device (arm64)
3. Archive for iOS Simulator (arm64)
4. Create XCFramework combining both archives

**Key Build Settings:**
- `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` (module stability)
- `SKIP_INSTALL=NO` (include framework in archive)
- `OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"` (build speed)
- `ARCHS="arm64"` (device)
- `EXCLUDED_ARCHS="x86_64"` (simulator, Apple Silicon only)

**Output Structure:**
```
build/
├── ios_theme_ui-iOS.xcarchive
├── ios_theme_ui-Simulator.xcarchive
└── (merged into) ios_theme_ui.xcframework/
    ├── Info.plist
    ├── ios-arm64/
    │   └── ios_theme_ui.framework/
    └── ios-arm64_x86_64-simulator/
        └── ios_theme_ui.framework/
```

---

## 4. Code Quality & Testing

### 4.1 SwiftLint Configuration

**epost-ios-theme-ui:**
- Included paths: `ios_theme_ui/Classes`
- Excluded paths: `.build`, `.swiftpm`, `Generated`, `Libraries`
- Line length: Warning 120, error 200
- Custom rule: No print/NSLog statements
- 40+ opt-in rules enabled

**SwiftyBeaver:**
- Included: `Sources`, `Tests`
- Excluded: `Carthage`, `Packages`, `.build`
- Disabled rules: valid_docs, cyclomatic_complexity, type_body_length, etc.
- Line length: 200 characters
- Reporter: Xcode format

### 4.2 Code Standards (CLAUDE.md)

**epost-ios-theme-ui specifics:**
- File headers: Author must be "Phuong Doan Duy", copyright "© 2025 AAVN"
- Border radius: Use `setBorderRadius()` from `ThemeCornerStyle.swift`
- Colors: Always use `ThemeColorPicker`, never direct `UIColor`
- Spacing: Use `ThemeGrid` values
- Build instruction: Use xcodebuild, NOT `swift build` (requires UIKit)

---

## 5. Integration Testing & Real-World Use Cases

### 5.1 Primary Use Case: epost-ios-theme-ui

**Demonstrates:**
1. **Complex Framework Structure**
   - 100+ UI components with variations
   - Theme system with brand colors
   - Resource bundles (fonts, images, JSON theme files)

2. **Multi-Platform Support**
   - iOS device (arm64)
   - iOS Simulator (arm64)
   - Deployment target handling (iOS 16.0)

3. **Build Settings Workarounds**
   - Module interface verification disabled (`-no-verify-emitted-module-interface`)
   - Architecture exclusion (x86_64 for simulator)
   - Library distribution settings enabled

4. **Dependency Management**
   - SPM dependency (AlignedCollectionViewFlowLayout)
   - Third-party embedded libraries (SwifterSwift, SwiftTheme, XCoordinator)
   - Resource processing in Package.swift

5. **Showcase Application**
   - Separate target (`theme-ui-showcase`) demonstrates component usage
   - Real UI examples for documentation

### 5.2 Secondary Example: SwiftyBeaver

**Demonstrates:**
- Mature Swift package structure
- Simple, focused library (no complex resources)
- Multi-platform support (iOS, macOS, server-side Swift)
- Docker-based testing approach
- CocoaPods + SPM distribution

---

## 6. How Examples Are Used for Testing

### 6.1 Integration Testing Strategy

**epost-ios-theme-ui serves as:**
1. **Real-world test case** for XCFramework CLI
   - Complex framework with real UI components
   - Resource management (fonts, images, theme JSON)
   - Dependency resolution

2. **Configuration validation**
   - Tests both .xcframework.yml and spm.yml configurations
   - Validates build settings handling
   - Tests architecture exclusion patterns

3. **Build output verification**
   - XCFramework structure validation
   - dSYM inclusion
   - Framework modulemap generation

### 6.2 Testing Workflow

**Development:**
```bash
cd Example/epost-ios-theme-ui
make build              # Build for simulator (development)
make lint              # Code quality checks
make lint-fix          # Auto-fix issues
```

**XCFramework Building:**
```bash
make xcframework-project  # Full release build
# Output: epost-ios-theme-ui.xcframework/
```

**Clean Up:**
```bash
make clean-xcframework    # Remove build artifacts
```

---

## 7. Key Build Requirements & Special Cases

### 7.1 epost-ios-theme-ui Special Requirements

1. **UIKit Dependency**
   - Must use `xcodebuild`, not `swift build`
   - Cannot build with CLI Swift compiler
   - Requires iOS SDK

2. **Module Interface Workaround**
   - Setting: `OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"`
   - Purpose: Speed up builds with AlignedCollectionViewFlowLayout dependency
   - Issue: Module interface verification can be slow with embedded libraries

3. **Resource Bundle Processing**
   - Package.swift: `.process("Resources/")`
   - Includes fonts (Frutiger Neue family)
   - Includes images (Icons, UI assets)
   - Includes theme JSON files (brand color definitions)

4. **Architecture Configuration**
   - Device: arm64 only
   - Simulator: arm64 (x86_64 excluded)
   - Rationale: Optimize for Apple Silicon Macs, reduce binary size

### 7.2 SwiftyBeaver Special Requirements

1. **No Platform-Specific Code**
   - Pure Swift, works on any platform
   - Server-side Swift supported
   - Can build with `swift build`

2. **Docker Testing**
   - Script: `test_in_docker.sh`
   - Validates builds on Linux (Ubuntu)
   - No dependencies on macOS-specific features

---

## 8. Configuration Patterns & Best Practices

### 8.1 Recommended Patterns from Examples

**For Single Framework Projects:**
```yaml
# Use if building from Xcode Project
project:
  name: framework_name
  xcode_project: Project.xcodeproj

frameworks:
  - name: FrameworkName
    scheme: FrameworkName
    platforms: [ios]
    deployment_targets:
      ios: "16.0"

build:
  output_dir: build
  clean_before_build: true
  configuration: Release
  verbose: true
```

**For SPM-Based Projects:**
```yaml
spm:
  package_dir: "."
  targets: ["TargetName"]
  platforms: [ios, ios-simulator]
  library_evolution: true
  version: "16.0"
```

**Build Settings for UIKit Frameworks:**
```yaml
build_settings:
  BUILD_LIBRARY_FOR_DISTRIBUTION: "YES"
  SKIP_INSTALL: "NO"
  OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
  EXCLUDED_ARCHS: "x86_64"  # For simulator on Apple Silicon
```

### 8.2 Code Quality Standards

**Required Tools:**
- SwiftLint (linting)
- SwiftFormat (formatting)
- xcbeautify or xcpretty (build output)

**Integration Points:**
- Makefile targets for CI/CD
- Pre-commit hooks for developers
- Xcode build phases for automated checks

---

## 9. Output Examples

### 9.1 XCFramework Output Structure

**Location:** `build/ios_theme_ui.xcframework/`

```
ios_theme_ui.xcframework/
├── Info.plist                          # Framework metadata
├── ios-arm64/                          # Device slice
│   ├── ios_theme_ui.framework/
│   │   ├── ios_theme_ui                # Binary
│   │   ├── Modules/
│   │   │   ├── ios_theme_ui.swiftmodule/
│   │   │   │   └── arm64-apple-ios.swiftinterface
│   │   │   └── module.modulemap
│   │   ├── Headers/
│   │   │   └── Umbrella.h
│   │   └── Info.plist
│   └── (dSYM files)
│
└── ios-arm64_x86_64-simulator/         # Simulator slice
    ├── ios_theme_ui.framework/
    │   ├── ios_theme_ui                # Binary
    │   ├── Modules/
    │   │   ├── ios_theme_ui.swiftinterface
    │   │   └── module.modulemap
    │   ├── Headers/
    │   └── Info.plist
    └── (dSYM files)
```

### 9.2 Build Artifacts

**Intermediate Archives:**
```
build/
├── ios_theme_ui-iOS.xcarchive/        # Device build
├── ios_theme_ui-Simulator.xcarchive/  # Simulator build
└── ios_theme_ui.xcframework/          # Final output
```

---

## 10. Unresolved Questions & Notes

### Potential Areas for Clarification

1. **SwiftyBeaver Integration**: SwiftyBeaver appears to be a dependency example rather than a framework being built. Is it used for testing XCFramework CLI's dependency handling?

2. **Showcase Target**: The theme-ui-showcase target in Package.swift - is it included in the XCFramework or is it a separate build artifact?

3. **Resource Bundles**: How are resource bundles (fonts, images, JSON) handled in the final XCFramework distribution? Are they included or must consumers manage them separately?

4. **CocoaPods Support**: epost-ios-theme-ui appears to be designed for CocoaPods distribution too (based on package design), but no .podspec is visible. Is CocoaPods distribution planned?

5. **Testing Integration**: No test target visible in the example. Is testing part of the XCFramework CLI workflow?

---

## Summary

The Example/ directory contains two complementary projects:

1. **epost-ios-theme-ui** - Production-grade UI framework demonstrating:
   - Complex XCFramework building from Xcode Project
   - Resource management (fonts, images, themes)
   - Custom build settings and workarounds
   - Multi-target approach (framework + showcase)
   - Integration with Swift Package Manager

2. **SwiftyBeaver** - Mature Swift package demonstrating:
   - Simple SPM structure
   - Multi-platform support
   - External dependency example

Both serve as integration tests for XCFramework CLI and demonstrate real-world usage patterns for framework distribution on Apple platforms.

