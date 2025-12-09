# Documentation Index

Comprehensive documentation for the XCFramework CLI project.

---

## 🚀 Getting Started

- **[Main README](../README.md)** - Installation, quick start, and usage guide
- **[CLAUDE.md](../CLAUDE.md)** - AI assistant development guide

---

## 🏗️ Architecture & Design

| Document | Description | Status |
|----------|-------------|--------|
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | High-level architecture overview with diagrams | ✅ Current |
| **[ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)** | Detailed module breakdown and design patterns | ✅ Current |

**What you'll learn:**
- Module structure and responsibilities
- Build pipeline flows (Xcode & SPM)
- Platform abstraction pattern
- Resource bundle implementation
- Design patterns used

---

## ⚙️ Configuration & Usage

| Document | Description | Status |
|----------|-------------|--------|
| **[CONFIGURATION.md](CONFIGURATION.md)** | Configuration file options and examples | ✅ Current |
| **[RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md](RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md)** | SPM resource bundle support details | ✅ Current |

**What you'll learn:**
- YAML/JSON configuration structure
- Custom build settings
- Platform-specific options
- Resource bundle handling
- SPM integration

---

## 📦 Resource Bundle Implementation

**Status**: ✅ Fully Implemented (SPM)

| Document | Description |
|----------|-------------|
| **[RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md](RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md)** | Complete implementation guide |
| **[RESOURCE_BUNDLE_IMPLEMENTATION_PLAN.md](RESOURCE_BUNDLE_IMPLEMENTATION_PLAN.md)** | Original implementation plan |
| **[RESOURCE_BUNDLE_STRUCTURE_COMPARISON.md](RESOURCE_BUNDLE_STRUCTURE_COMPARISON.md)** | Structure analysis and comparison |

**Key features:**
- Automatic bundle detection
- Custom `Bundle.module` accessor
- Symlink resolution
- Multi-architecture support

---

## 🧪 Development & Contributing

| Document | Description | Status |
|----------|-------------|--------|
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Development setup and contribution guidelines | ✅ Current |
| **[CHANGELOG.md](CHANGELOG.md)** | Version history and changes | ✅ Current |

**What you'll learn:**
- Development workflow
- Testing conventions (109 tests, 68% coverage)
- Code style guidelines
- Commit message conventions
- Pull request process

---

## 📋 Document Status Legend

| Status | Description |
|--------|-------------|
| ✅ Current | Actively maintained, reflects current implementation |
| 📚 Reference | Planning/design documents for context |
| 🗄️ Archived | Historical reference, may be outdated |

---

## 🗂️ Document Organization

### Active Documentation (Current Implementation)
Documents that reflect the current Ruby CLI implementation:
- ARCHITECTURE.md
- ARCHITECTURE_OVERVIEW.md
- CONFIGURATION.md
- RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md
- CONTRIBUTING.md
- CHANGELOG.md

### Reference Documentation (Planning & Design)
Documents that provide historical context and design decisions:
- RESOURCE_BUNDLE_IMPLEMENTATION_PLAN.md
- RESOURCE_BUNDLE_STRUCTURE_COMPARISON.md

### Project Structure

```
docs/
├── README.md                                    # This index
├── ARCHITECTURE.md                              # High-level architecture
├── ARCHITECTURE_OVERVIEW.md                     # Detailed architecture
├── CONFIGURATION.md                             # Configuration guide
├── CONTRIBUTING.md                              # Development guide
├── CHANGELOG.md                                 # Version history
├── RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md   # Resource bundle guide
├── RESOURCE_BUNDLE_IMPLEMENTATION_PLAN.md       # Implementation plan
└── RESOURCE_BUNDLE_STRUCTURE_COMPARISON.md      # Structure comparison
```

---

## 🔍 Quick Reference

### For New Users
1. Start with [Main README](../README.md)
2. Review [ARCHITECTURE.md](ARCHITECTURE.md) for system overview
3. Check [CONFIGURATION.md](CONFIGURATION.md) for setup options

### For Contributors
1. Read [CONTRIBUTING.md](CONTRIBUTING.md) for development setup
2. Review [CLAUDE.md](../CLAUDE.md) for AI assistant guidance
3. Study [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md) for detailed design

### For Implementers
1. See [ARCHITECTURE.md](ARCHITECTURE.md) for build flows
2. Check [RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md](RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md) for resource handling
3. Review code in `lib/xcframework_cli/` with architecture docs

---

## 📝 Notes

- **Legacy bash scripts**: Removed from repository. Ruby CLI provides all functionality.
- **Phase 1 complete**: iOS and iOS Simulator platforms fully implemented and tested.
- **Resource bundles**: Fully implemented for SPM builds with custom Bundle.module support.
- **Platform expansion**: macOS, tvOS, watchOS, visionOS, Catalyst planned for Phase 2.

---

**Last Updated**: December 9, 2025
**Repository Status**: ✅ Production Ready for iOS
