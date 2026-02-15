# XCFramework CLI Documentation Index

**Last Updated:** February 15, 2026  
**Version:** 0.2.0 - Phase 1 Complete

Quick navigation for all documentation resources.

---

## Getting Started

| Document | Purpose | Audience | Time |
|----------|---------|----------|------|
| [README.md](../README.md) | Installation, features, quick start | Users, New Developers | 10 min |
| [Quick Reference](#quick-reference) | Essential commands and config | Users | 5 min |

---

## Learning the Project

### For New Developers
1. **Start here:** [Codebase Summary](./codebase-summary.md) - Architecture overview (20 min)
2. **Understand:** [System Architecture](./system-architecture.md) - Detailed design and data flows (30 min)
3. **Code:** [Code Standards](./code-standards.md) - Conventions and patterns (25 min)
4. **Run:** `bundle exec rake spec` to see tests pass
5. **Explore:** `lib/xcframework_cli/` to read actual code

### For Architects & Planners
1. [Project Overview & PDR](./project-overview-pdr.md) - Vision, requirements, success metrics
2. [Project Roadmap](./project-roadmap.md) - Phases, timeline, risks
3. [System Architecture](./system-architecture.md) - Detailed design

### For Contributors
1. [Code Standards](./code-standards.md) - Patterns and conventions
2. [System Architecture](./system-architecture.md) - Extension points
3. [CONTRIBUTING.md](./CONTRIBUTING.md) - How to contribute

---

## Reference Documentation

| Document | Purpose |
|----------|---------|
| [System Architecture](./system-architecture.md) | Detailed system design, layers, data flows, extension points |
| [Code Standards](./code-standards.md) | Ruby conventions, testing patterns, error handling |
| [Codebase Summary](./codebase-summary.md) | Module hierarchy, classes, design patterns |
| [Configuration Guide](./CONFIGURATION.md) | Complete config options and examples |
| [Project Roadmap](./project-roadmap.md) | Phases, timeline, future features |
| [Project Overview](./project-overview-pdr.md) | Vision, requirements, success metrics |

---

## Specialized Guides

| Document | Purpose |
|----------|---------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Conceptual architecture (legacy, see System Architecture) |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | How to contribute to the project |
| [CHANGELOG.md](./CHANGELOG.md) | Release history and changes |

---

## Quick Reference

### Installation
```bash
git clone https://github.com/phuongddx/xcframework-cli.git
cd xcframework-cli
bundle install
./bin/xckit version
```

### Build Commands

**Xcode Project:**
```bash
./bin/xckit build --config .xcframework.yml --verbose
```

**Swift Package:**
```bash
./bin/xckit spm build --package-dir . --platforms ios ios-simulator
```

**Initialize Config:**
```bash
./bin/xckit init
```

### Configuration Template

**Xcode Project:**
```yaml
project:
  name: MyFramework
  xcode_project: MyFramework.xcodeproj

frameworks:
  - name: MyFramework
    scheme: MyFramework
    platforms: [ios, ios-simulator]

build:
  output_dir: build
  configuration: Release
```

**Swift Package:**
```yaml
spm:
  package_dir: "."
  targets: [MyLibrary]
  platforms: [ios, ios-simulator]

build:
  output_dir: build
  configuration: Release
```

### Key Commands
```bash
# Test (80% coverage required)
bundle exec rake spec

# Lint
bundle exec rake rubocop
bundle exec rake lint_fix

# Console
bundle exec rake console

# Default (spec + rubocop)
bundle exec rake
```

---

## Key Concepts

### Modules (11 Layers)
1. **CLI** - Command dispatcher (Thor)
2. **Config** - YAML/JSON loading and validation
3. **Builder** - Build orchestration (clean → archive → xcframework)
4. **Platform** - Platform abstraction (iOS, iOS Simulator, others planned)
5. **Xcodebuild** - Xcode integration
6. **SPM** - Swift Package Manager integration
7. **Swift** - Swift compiler wrapper
8. **Project** - Auto-detection of projects
9. **Utils** - Logging, progress, templates
10. **Errors** - Custom error hierarchy
11. **Version** - Version constant

### Design Patterns
- **Factory** - Platform::Registry.create('ios')
- **Builder** - Multi-step pipeline (Clean → Archive → XCFramework)
- **Template Method** - Platform::Base defines interface
- **Strategy** - Config loading (file vs CLI args)
- **Registry** - SDK management

### Architecture Layers
```
CLI → Commands → Config → Orchestration → Platform/Tools → External Tools
```

---

## Project Status

**Current:** Version 0.2.0 - Phase 1 Complete (iOS/iOS Simulator)

| Phase | Status | Timeline |
|-------|--------|----------|
| 1: Foundation | ✅ Complete | Aug-Dec 2025 |
| 2: Platform Expansion | 🚧 Planned | Q1-Q2 2026 |
| 3: Resource Management | 🚧 Planned | Q2 2026 |
| 4: Publishing Pipeline | 🚧 Planned | Q2-Q3 2026 |
| 5: Advanced Features | 📋 Future | Q3+ 2026 |

See [Project Roadmap](./project-roadmap.md) for details.

---

## Statistics

- **Implementation:** 31 Ruby files, 4,645 LOC
- **Tests:** 23 test files, 4,419 LOC, 280+ examples
- **Coverage:** 85%+ (80% minimum enforced)
- **Documentation:** 2,500+ LOC across 6 files
- **Dependencies:** 4 runtime gems (thor, dry-validation, colorize, tty-spinner)

---

## Common Tasks

### Adding a New Platform
1. Create `lib/xcframework_cli/platform/[name].rb` (~50 LOC)
2. Inherit from `Platform::Base` and implement 6 class methods
3. Register in `Platform::Registry::PLATFORMS`
4. Add tests in `spec/unit/platform/[name]_spec.rb`
5. Update examples in `config/examples/`

See [System Architecture](./system-architecture.md) → Extension Points

### Adding a Build Step
1. Create `Builder::YourStep` class
2. Implement `execute` method returning `{ success: bool, data: ... }`
3. Integrate into `Builder::Orchestrator#build`
4. Add unit tests

### Configuration Schema Changes
1. Update `Config::Schema` validation rules
2. Update `Config::Defaults` with default values
3. Update examples in `config/examples/`
4. Add tests in `spec/unit/config/loader_spec.rb`

---

## Resources

| Resource | Location | Purpose |
|----------|----------|---------|
| Main entry | `lib/xcframework_cli.rb` | Loads all modules |
| Example projects | `Example/` | Real-world usage |
| Config examples | `config/examples/` | Reference templates |
| Test suite | `spec/` | 280+ test cases |
| Coverage report | `coverage/index.html` (generated) | Test coverage detail |

---

## Help & Support

```bash
# Show all commands
./bin/xckit --help

# Show command help
./bin/xckit build --help

# Run with verbose output
./bin/xckit build --config .xcframework.yml -v

# Interactive console (loads gem)
bundle exec rake console
```

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- How to report bugs
- How to suggest features
- How to submit pull requests
- Code review process

---

## Questions?

1. **Architecture Questions:** See [System Architecture](./system-architecture.md)
2. **Code Questions:** See [Code Standards](./code-standards.md)
3. **Build Questions:** See [Codebase Summary](./codebase-summary.md)
4. **Product Questions:** See [Project Overview](./project-overview-pdr.md)
5. **Future Plans:** See [Project Roadmap](./project-roadmap.md)

---

**Last Updated:** February 15, 2026  
**Documentation Version:** 1.0 (Complete)
