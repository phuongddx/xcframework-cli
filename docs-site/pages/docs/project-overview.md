# Project Overview & Product Requirements

**Last Updated:** February 15, 2026
**Current Version:** 0.2.0
**Status:** Phase 1 Complete (iOS/iOS Simulator)

---

## Executive Summary

XCFramework CLI automates XCFramework creation from Xcode projects and Swift Packages. It replaces manual shell scripts and complex build configurations with a simple YAML/JSON-based approach.

**Core Value:** Reduce framework build time from 30+ minutes of manual steps to single commands, with consistent output and helpful error guidance.

---

## Product Vision

Enable iOS/Apple framework developers to:
1. Build XCFrameworks with minimal configuration
2. Distribute frameworks across all Apple platforms reliably
3. Manage complex resource bundles (fonts, images, themes)
4. Automate framework publishing pipelines

Success metric: Framework developers choose XCFramework CLI over manual bash scripts.

---

## Target Users

**Primary:** Framework/SDK developers building libraries for iOS/macOS distribution
**Secondary:** DevOps engineers automating CI/CD framework builds
**Tertiary:** Enterprise teams managing internal framework repositories

---

## Core Functional Requirements

### FR1: Build from Xcode Projects
- Load `.xcodeproj` or `.xcworkspace`
- Execute platform-specific archive builds
- Merge archives into single XCFramework
- **Status:** Complete (iOS, iOS Simulator)

### FR2: Build from Swift Packages
- Parse `Package.swift` with swift package dump-package
- Compile via swift build with platform-specific SDK triples
- Create framework structure with libtool binaries
- Combine architectures with lipo
- **Status:** Complete (iOS, iOS Simulator)

### FR3: Configuration Management
- Support YAML and JSON configuration files
- Validate against schema using dry-validation
- Auto-discover config files (`.xcframework.yml`, etc.)
- Apply default values for missing keys
- **Status:** Complete

### FR4: Multi-Platform Support
- iOS device (arm64)
- iOS Simulator (arm64, x86_64)
- Schema defined for: macOS, tvOS, tvOS Simulator, watchOS, watchOS Simulator, visionOS, visionOS Simulator, Catalyst
- **Status:** iOS Complete | Others Planned

### FR5: Resource Bundle Management
- Detect resource bundles in frameworks
- Generate Bundle.module code for access
- Handle fonts, images, JSON configuration files
- **Status:** In Progress

### FR6: Custom Build Settings
- Override Xcode defaults per framework
- Support all xcodebuild KEY=VALUE pairs
- Common presets for known issues
- **Status:** Complete

### FR7: Error Handling & Guidance
- Capture detailed error messages
- Provide actionable suggestions
- Guide users through common issues
- **Status:** Complete

---

## Non-Functional Requirements

| Requirement | Target | Status |
|-------------|--------|--------|
| Test Coverage | 80% minimum | Enforced |
| Ruby Version | 3.0+ support | Complete |
| Build Output | < 2 minutes (iOS) | Achieved |
| Error Messages | < 10 seconds feedback | Complete |
| Dependencies | < 5 runtime gems | Complete (4) |
| Code Quality | Rubocop compliant | Enforced |

---

## Architecture Principles

1. **Modular Design** - Each layer (CLI, Config, Build, Platform) independent
2. **Configuration-Driven** - No hardcoded values; everything from config/CLI
3. **Platform Abstraction** - New platforms need only 3 class methods
4. **Fail-Fast Validation** - Catch errors before build starts
5. **External Tool Wrapping** - Thin shells around xcodebuild/swift

---

## Dependencies

### Runtime Gems (4 total)
- **thor** (v1.2+) - CLI framework
- **dry-validation** (v1.8+) - Configuration schema
- **colorize** (v0.8+) - Terminal colors
- **tty-spinner** (v0.9+) - Progress indicators

### External Tools
- **xcodebuild** (Xcode 12+)
- **swift** (Swift 5.0+)
- **xcrun** (Xcode utilities)
- **xcbeautify** or **xcpretty** (optional, for formatted output)

---

## Competitive Landscape

### Alternatives
- **Manual bash scripts** - Cumbersome, error-prone, non-portable
- **Fastlane** - Overkill for framework building; slower startup
- **Swift Package Manager** - Limited to SPM; no Xcode project support
- **CocoaPods** - Primarily for dependency management; not build automation

### Advantages
1. Lightweight (4 gems vs Fastlane's 50+)
2. Fast startup (<1 second)
3. Explicit configuration (YAML/JSON) over conventions
4. Single responsibility (XCFrameworks only)
5. Framework author focused (not consumer)
