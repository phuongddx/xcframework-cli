---
title: Roadmap
parent: Project Overview
nav_order: 1
---

# XCFramework CLI - Project Roadmap

**Last Updated:** February 15, 2026
**Current Version:** 0.2.0
**Overall Progress:** 25% (Phase 1/4 complete)

---

## Executive Summary

XCFramework CLI is transitioning from a foundation phase to platform expansion. Phase 1 (iOS/iOS Simulator) is production-ready with 280+ tests and 85% code coverage. The roadmap focuses on multi-platform support, advanced resource handling, and publishing automation.

**Next Milestone (Q1 2026):** macOS, tvOS, watchOS, visionOS, Catalyst support

---

## Phase Overview

```
Phase 1: Foundation              ✅ COMPLETE (Aug-Dec 2025)
├─ iOS & iOS Simulator          ✅
├─ Xcode project builds         ✅
├─ SPM builds                   ✅
└─ Test framework (280+ tests)  ✅

Phase 2: Platform Expansion      🚧 Q1-Q2 2026 (8-10 weeks)
├─ macOS support
├─ tvOS & tvOS Simulator
├─ watchOS & watchOS Simulator
├─ visionOS
└─ Catalyst

Phase 3: Resource Management     🚧 Q2 2026 (6-8 weeks)
├─ Template-based compilation
├─ Font bundling automation
├─ Asset catalog processing
└─ Multi-language support

Phase 4: Publishing Pipeline     🚧 Q2-Q3 2026 (8-10 weeks)
├─ Artifactory integration
├─ Git tag creation
├─ Version management
└─ Release notes generation

Phase 5: Advanced Features       📋 Q3+ 2026 (ongoing)
├─ Incremental builds
├─ Parallel compilation
├─ DSym management
└─ Performance optimization
```

---

## Phase 1: Foundation - COMPLETE ✅

**Timeline:** August 1 - December 6, 2025 (18 weeks)
**Status:** Production Ready

### Deliverables
- ✅ Ruby CLI with Thor command dispatcher
- ✅ Configuration management (YAML/JSON validation)
- ✅ iOS device support (arm64)
- ✅ iOS Simulator support (arm64, x86_64)
- ✅ Xcode project build pipeline
- ✅ Swift Package Manager build pipeline
- ✅ 280+ RSpec test cases
- ✅ 85%+ code coverage
- ✅ Error handling with user suggestions
- ✅ Colored output with formatters
- ✅ Basic documentation

### Key Achievements
- Modular architecture with 11 distinct layers
- Platform abstraction pattern for future expansion
- Full Xcode archive → XCFramework flow
- Complete SPM package parsing → framework creation → XCFramework
- Comprehensive test coverage
- Zero production dependencies on external gems (only Thor, dry-validation, colorize, tty-spinner)

### Known Limitations (Phase 1)
1. Only iOS/iOS Simulator (8 other platforms in schema but not implemented)
2. Resource bundles detected but limited automation
3. No incremental builds (always full rebuild)
4. No integrated publishing (manual upload to repositories)
5. Single framework per config (multi-framework requires multiple runs)

---

## Phase 2: Platform Expansion - PLANNED

**Timeline:** Q1-Q2 2026 (January - April)
**Estimated Effort:** 8-10 weeks
**Status:** Planned

### Platform Additions

| Platform | Architectures | Deployment Target | Effort | Priority |
|----------|---------------|-------------------|--------|----------|
| macOS | arm64, x86_64 | 11.0 | 1 week | High |
| tvOS | arm64 | 14.0 | 5 days | High |
| tvOS Simulator | arm64 | 14.0 | 3 days | Medium |
| watchOS | arm64, armv7k | 7.0 | 1 week | High |
| watchOS Simulator | x86_64, i386 | 7.0 | 5 days | Medium |
| visionOS | arm64 | 1.0 | 1 week | Medium |
| Catalyst | arm64, x86_64 | 14.0 | 5 days | Low |

### Implementation Pattern

Each platform requires only ~50-100 LOC:
```ruby
class Platform::macOS < Base
  def self.platform_name; 'macOS'; end
  def self.platform_identifier; 'macos'; end
  def self.sdk_name; 'macosx'; end
  def self.destination; 'generic/platform=macOS'; end
  def self.valid_architectures; %w[arm64 x86_64]; end
  def self.default_deployment_target; '11.0'; end
  def self.default_architectures
    { 'macos' => %w[arm64 x86_64] }
  end
end
```

Plus:
- 30-50 lines of tests per platform
- Update registry and schema
- Document in examples

### Success Criteria
- ✅ All 10 Apple platforms supported
- ✅ 280+ test cases remain passing
- ✅ Code coverage ≥ 80%
- ✅ No breaking API changes
- ✅ Real-world testing (macOS, tvOS at minimum)

### Testing Strategy
- Unit tests for each platform class
- Integration test for multi-platform build
- Example project demonstrating macOS framework
- CI/CD pipeline testing

### Risk Assessment
- **Low Risk:** Platform implementation uses existing pattern
- **Medium Risk:** Deployment target variation across platforms
- **Mitigation:** Schema defines all values; tests validate

---

## Phase 3: Resource Management - PLANNED

**Timeline:** Q2 2026 (April - May)
**Estimated Effort:** 6-8 weeks
**Status:** Planned

### Current State
- Basic resource bundle detection
- Manual Bundle.module code generation
- Limited support for complex resources

### Enhancements

#### 1. Automatic Bundle.module Generation
```ruby
# Current: Manual in framework
enum BundleInfo {
  static let module = Bundle(identifier: "com.example.MyFramework")!
}

# Phase 3: Auto-generated
Builder::ResourceManager.generate_bundle_access(framework)
```

#### 2. Font Bundling Automation
- Detect font files in resources
- Register with Info.plist
- Generate font loading utilities

#### 3. Asset Catalog Processing
- Convert Assets.xcassets to data assets
- Generate asset accessors
- Support image tinting and scaling

#### 4. Localization Support
- Process .lproj directories
- Generate string accessors
- Multi-language manifest

#### 5. Configuration Templates
```yaml
resources:
  fonts:
    - "Frutiger Neue"
    - "OpenSans"
  assets:
    - path: "Assets.xcassets"
      generate_accessors: true
  localization:
    - "en"
    - "fr"
    - "es"
```

### Implementation Plan
1. Create `Builder::ResourceManager` class
2. Extend `Builder::Orchestrator` to include resource phase
3. Update config schema with resource options
4. Create template generators for common patterns
5. Add 50+ test cases

### Success Criteria
- ✅ Fonts bundled automatically
- ✅ Assets processed with accessors
- ✅ Localization handled
- ✅ 90%+ coverage of resource scenarios
- ✅ No manual template editing needed

---

## Phase 4: Publishing Pipeline - PLANNED

**Timeline:** Q2-Q3 2026 (May - July)
**Estimated Effort:** 8-10 weeks
**Status:** Planned

### Integrations

#### 1. Artifactory
```ruby
Builder::Publisher.new(config).publish_artifactory
# Uploads to: artifactory.example.com/frameworks/MySDK/0.1.0/
```

Configuration:
```yaml
publishing:
  artifactory:
    url: https://artifactory.example.com
    repository: frameworks
    api_key: ${ARTIFACTORY_KEY}  # From environment
```

#### 2. Git Integration
```ruby
Builder::Publisher.publish_git_tag
# Creates tag: v0.1.0
# Pushes to origin
```

#### 3. Version Management
- Semantic versioning auto-increment
- Version bumping rules
- Changelog generation

#### 4. Release Notes
- Extract from git commit history
- Format for distribution
- Generate downloadable assets list

### Implementation Plan
1. Create `Builder::Publisher` class
2. Add `Publish::Artifactory` integration
3. Add `Publish::Git` integration
4. Extend CLI with `publish` command
5. Create configuration templates

### Success Criteria
- ✅ One-command publishing
- ✅ Multiple destination support
- ✅ Automatic versioning
- ✅ Release notes generation
- ✅ Rollback capability

---

## Phase 5: Advanced Features - FUTURE

**Timeline:** Q3+ 2026 (ongoing)
**Status:** Research & Planning

### 1. Incremental Builds
- Cache framework slices
- Skip unchanged platforms
- Detect source changes
- Estimated time savings: 40-50%

### 2. Parallel Compilation
- Multi-threaded platform builds
- Concurrent SDK compilation
- Potential time savings: 30-40% (Amdahl's Law limited)

### 3. DSym Management
- Symbol upload to services (Sentry, etc.)
- Archive symbol persistence
- Crash stack trace symbolication

### 4. Performance Profiling
- Build time breakdown per step
- Hotspot identification
- Optimization recommendations

### 5. Integration Improvements
- Fastlane plugin
- GitHub Actions support
- GitLab CI integration

---

## Current Status (v0.2.0)

### What Works ✅
- iOS device (arm64) builds
- iOS Simulator (arm64, x86_64) builds
- Xcode project build pipeline
- SPM (Swift Package) build pipeline
- Configuration validation
- Error handling with suggestions
- Colored output and formatting
- 280+ test cases
- Real-world example projects

### What's In Progress 🚧
- Resource bundle automation
- Complete documentation
- Additional platform support (code written, not released)

### What's Not Done ❌
- macOS and other platforms (Phase 2)
- Advanced resource handling (Phase 3)
- Publishing integration (Phase 4)
- Incremental builds (Phase 5)

---

## Community Roadmap

### Contribution Opportunities
1. **Platform Implementation** - Add watchOS, visionOS support
2. **Documentation** - Expand guides, add tutorials
3. **Examples** - Create example frameworks
4. **Testing** - Increase integration test coverage
5. **Performance** - Profile and optimize
6. **Integration** - Fastlane, CI/CD plugins

### Development Process
1. Fork repository
2. Create feature branch
3. Implement with tests
4. Submit PR with description
5. Code review + refinement
6. Merge to main

---

## Version Management

| Version | Date | Status | Highlights |
|---------|------|--------|-----------|
| 0.1.0 | Nov 2025 | Archived | Initial release; iOS partial |
| 0.2.0 | Feb 2026 | Current | Phase 1 complete; iOS full |
| 0.3.0 | May 2026 | Planned | Platform expansion (Phase 2) |
| 0.4.0 | Aug 2026 | Planned | Resource management (Phase 3) |
| 0.5.0 | Oct 2026 | Planned | Publishing pipeline (Phase 4) |
| 1.0.0 | Q4 2026 | Planned | All platforms, stable API |

---

## Success Metrics

### Phase 1 Results
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Test coverage | 80% | 85% | ✅ Exceeded |
| Build time (iOS) | < 3 min | 2-3 min | ✅ Met |
| Platforms | 1-2 | 2 | ✅ Met |
| Documentation | Partial | Basic | ✅ Met |
| Production usage | 1 org | 2 teams | ✅ Exceeded |

### Phase 2 Goals
| Metric | Target | Timeline |
|--------|--------|----------|
| All 10 platforms supported | 100% | Q2 2026 |
| Test coverage | 80%+ | Q2 2026 |
| Example projects | 3+ | Q1 2026 |
| Adoption | 5+ orgs | Q2 2026 |

---

## Risk Registry

### Phase 2 Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Deployment target variance | Medium | Low | Schema validation |
| Architecture incompatibility | Low | High | Testing on real devices |
| Xcode version incompatibility | Low | Medium | Version pinning |

### Phase 3 Risks
| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Resource complexity | High | High | Iterative design, community feedback |
| Template maintenance | Medium | Medium | Clear documentation |
| Performance impact | Low | Medium | Benchmarking |

---

## Deprecation Policy

### Backward Compatibility
- v0.2.x: No breaking changes after launch
- v0.3.0: Minor API changes announced 2 releases ahead
- v1.0.0: Stable API, semantic versioning

### Deprecation Timeline
1. Feature marked deprecated in release notes
2. Still supported for 2 minor versions
3. Removed in next major version

---

## Open Questions & Decisions Needed

1. **Parallel Builds**: Worth the complexity vs. time savings?
2. **DSym Handling**: Build tool responsibility or user's?
3. **Artifact Storage**: Support multiple storage backends?
4. **Version Tagging**: Automatic or manual confirmation?
5. **Multi-Framework Support**: Single config or multiple?

---

## Communication & Updates

- **Weekly Status**: Internal team sync
- **Monthly Updates**: Public releases/announcements
- **Quarterly Reviews**: Roadmap adjustments
- **Community Input**: GitHub Discussions, Issues

---

## Glossary

| Term | Definition |
|------|-----------|
| XCFramework | Apple's binary framework format for distribution |
| DSym | Debug Symbol file for crash symbolication |
| Deployment Target | Minimum OS version supported |
| Architecture | CPU architecture (arm64, x86_64, etc.) |
| SDK | Software Development Kit for platform |
| Artifactory | Binary repository manager by JFrog |

