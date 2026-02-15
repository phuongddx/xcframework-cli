# XCFramework CLI - Project Overview & Product Requirements

**Last Updated:** February 15, 2026
**Current Version:** 0.2.0
**Status:** Phase 1 Complete (iOS/iOS Simulator)

---

## Executive Summary

XCFramework CLI is a command-line tool and Ruby gem that streamlines the creation and distribution of XCFrameworks across Apple's ecosystem. It replaces manual shell scripts and complex build configurations with a simple YAML/JSON-based approach, supporting both Xcode projects and Swift Packages.

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
- **Status:** ✅ Complete (iOS, iOS Simulator)

### FR2: Build from Swift Packages
- Parse `Package.swift` with swift package dump-package
- Compile via swift build with platform-specific SDK triples
- Create framework structure with libtool binaries
- Combine architectures with lipo
- **Status:** ✅ Complete (iOS, iOS Simulator)

### FR3: Configuration Management
- Support YAML and JSON configuration files
- Validate against schema using dry-validation
- Auto-discover config files (`.xcframework.yml`, etc.)
- Apply default values for missing keys
- **Status:** ✅ Complete

### FR4: Multi-Platform Support
- iOS device (arm64)
- iOS Simulator (arm64, x86_64)
- Schema defined for: macOS, tvOS, tvOS Simulator, watchOS, watchOS Simulator, visionOS, visionOS Simulator, Catalyst
- **Status:** ✅ iOS Complete | 🚧 Others Planned

### FR5: Resource Bundle Management
- Detect resource bundles in frameworks
- Generate Bundle.module code for access
- Handle fonts, images, JSON configuration files
- **Status:** 🚧 In Progress

### FR6: Custom Build Settings
- Override Xcode defaults per framework
- Support all xcodebuild KEY=VALUE pairs
- Common presets for known issues (module interface verification, simulator arch exclusion)
- **Status:** ✅ Complete

### FR7: Error Handling & Guidance
- Capture detailed error messages
- Provide actionable suggestions
- Guide users through common issues
- **Status:** ✅ Complete

---

## Non-Functional Requirements

| Requirement | Target | Status |
|-------------|--------|--------|
| Test Coverage | 80% minimum | ✅ Enforced |
| Ruby Version | 3.0+ support | ✅ Complete |
| Build Output | < 2 minutes (iOS) | ✅ Achieved |
| Error Messages | < 10 seconds feedback | ✅ Complete |
| Dependencies | < 5 runtime gems | ✅ Complete (4) |
| Code Quality | Rubocop compliant | ✅ Enforced |
| Documentation | All public APIs documented | 🚧 In Progress |

---

## Architecture Principles

1. **Modular Design** - Each layer (CLI, Config, Build, Platform) independent
2. **Configuration-Driven** - No hardcoded values; everything from config/CLI
3. **Platform Abstraction** - New platforms need only 3 class methods
4. **Fail-Fast Validation** - Catch errors before build starts
5. **External Tool Wrapping** - Thin shells around xcodebuild/swift (not reimplementation)

---

## Current Phase (Phase 1): Foundation - COMPLETE

**Timeline:** August 2025 - December 2025

**Deliverables:**
- ✅ CLI interface with Thor
- ✅ Configuration schema validation (dry-validation)
- ✅ Xcode project build pipeline (archive → xcframework)
- ✅ SPM build pipeline (build → framework creation → xcframework)
- ✅ iOS and iOS Simulator platform implementations
- ✅ 280+ test cases with 80%+ coverage
- ✅ Error handling with user suggestions
- ✅ Basic documentation

---

## Planned Phases

### Phase 2: Platform Expansion (Q1-Q2 2026)
- macOS, tvOS, watchOS, visionOS, Catalyst support
- Platform registry pattern reused
- Each platform ~50 LOC

### Phase 3: Resource Management (Q2 2026)
- Template-based resource compilation
- Font bundling automation
- Asset catalog processing
- Multi-language string localization

### Phase 4: Publishing Pipeline (Q2-Q3 2026)
- Artifactory integration
- Git tag creation
- Version management
- Release notes generation

### Phase 5: Advanced Features (Q3+ 2026)
- Incremental builds with caching
- Parallel platform compilation
- DSym management and upload
- Performance benchmarking

---

## Success Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Build time reduction | 70% vs manual | 75% ✅ |
| Test coverage | 80%+ | 85% ✅ |
| Configuration errors caught | 100% | 95% ✅ |
| User satisfaction | 4.5/5 | TBD |
| Adoption rate | 5+ orgs/quarter | 2 teams ✓ |

---

## Known Limitations & Constraints

### Current Limitations
1. **Platform Coverage** - Only iOS/iOS Simulator; others require Phase 2
2. **Resource Bundles** - Basic support; advanced scenarios TBD
3. **SPM Only** - Package.swift parsing; no support for other manifest formats
4. **No Caching** - Each build is full rebuild
5. **Single Framework** - Per-config; multi-framework projects need multiple runs

### Technical Constraints
- Ruby 3.0+ requirement (no older Rails compatibility needed)
- Xcode 12+ (uses modern xcodebuild features)
- macOS only (no Windows/Linux support planned)
- No codesigning (delegate to Xcode or separate tool)

### Architectural Constraints
- All builds via xcodebuild or swift (no reimplementation of compiler)
- Configuration file must exist before build (no interactive prompts during build)
- Output directory created if missing; cleanup manual
- No built-in version management or semantic versioning

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

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|-----------|
| xcodebuild failures | High | Medium | Comprehensive error wrapping, suggestions |
| Swift compiler bugs | Medium | Low | Version pinning, workaround settings |
| Resource bundle complexity | High | Medium | Phase 3 planning, community feedback |
| Platform parity challenges | Medium | High | Template method pattern, test coverage |
| Configuration bloat | Medium | Medium | Sensible defaults, schema validation |

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

---

## Open Questions & Follow-ups

1. **Resource Bundle Strategy**: How to handle complex scenarios (multiple bundles, nested resources)?
2. **Version Management**: Should XCFramework CLI manage version tagging or delegate?
3. **Parallel Builds**: Phase 2 - parallelize platform builds to reduce total time?
4. **CocoaPods Support**: Planned or out of scope?
5. **Caching Strategy**: Incremental builds - what granularity (per-platform, per-arch)?

---

## Success Definition

XCFramework CLI is successful when:

- ✅ iOS/iOS Simulator builds work reliably (Phase 1)
- 🚧 All major Apple platforms supported (Phase 2)
- 🚧 Resource bundles handled automatically (Phase 3)
- 🚧 Publishing pipelines integrated (Phase 4)
- 📋 3+ production teams actively using
- 📋 Maintenance < 5 hours/week
- 📋 Community contributions integrated

---

## Version History

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| 0.1.0 | Nov 2025 | Archived | Initial release (incomplete) |
| 0.2.0 | Feb 2026 | Current | Phase 1 complete; iOS fully working |
| 0.3.0 | Q2 2026 | Planned | Platform expansion (macOS, tvOS, etc.) |

