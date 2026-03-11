---
title: Codebase Summary
parent: Developer Guide
nav_order: 1
---

# XCFramework CLI - Codebase Summary

**Last Updated:** February 15, 2026
**Files:** 31 (lib/), 23 (spec/)
**LOC:** 4,645 (implementation) + 4,419 (tests)

---

## Quick Navigation

- **Gem Entry:** `lib/xcframework_cli.rb` - loads all modules
- **CLI Dispatcher:** `lib/xcframework_cli/cli/runner.rb` - Thor command routing
- **Build Pipeline:** `lib/xcframework_cli/builder/orchestrator.rb` - coordinates build flow
- **Platform Registry:** `lib/xcframework_cli/platform/registry.rb` - creates platform instances
- **Configuration:** `lib/xcframework_cli/config/loader.rb` - YAML/JSON loading and validation
- **Tests:** `spec/unit/` - 280+ test cases, 80%+ coverage

---

## Module Hierarchy

```
XCFrameworkCLI/
├── CLI/                          # Command-line interface (Thor)
│   ├── Runner (220 LOC)         # Command dispatcher
│   └── Commands/
│       ├── Build (182 LOC)      # Xcode project builds
│       ├── SPM (127 LOC)        # Swift Package builds
│       └── Init (181 LOC)       # Config generation
│
├── Builder/                      # Build orchestration
│   ├── Orchestrator (318 LOC)   # Pipeline coordinator
│   ├── Archiver (188 LOC)       # Archive creation
│   ├── Cleaner (147 LOC)        # Artifact cleanup
│   └── XCFramework (173 LOC)    # XCFramework assembly
│
├── Config/                       # Configuration management
│   ├── Loader (132 LOC)         # File discovery & parsing
│   ├── Schema (127 LOC)         # Dry-validation rules
│   ├── Defaults (104 LOC)       # Default values
│   └── Generator (125 LOC)      # Template generation
│
├── Platform/                     # Platform abstraction
│   ├── Base (147 LOC)           # Abstract interface
│   ├── IOS (42 LOC)             # iOS device
│   ├── IOSSimulator (42 LOC)    # iOS Simulator
│   └── Registry (96 LOC)        # Factory pattern
│
├── Xcodebuild/                   # xcodebuild wrapper
│   ├── Wrapper (167 LOC)        # Command execution
│   ├── Result (51 LOC)          # Result encapsulation
│   └── Formatter (189 LOC)      # Output beautification
│
├── SPM/                          # Swift Package support
│   ├── Package (315 LOC)        # Manifest parsing
│   ├── FrameworkSlice (495 LOC) # Single SDK framework
│   └── XCFrameworkBuilder (313  # Multi-SDK aggregator
│
├── Swift/                        # Swift compiler wrapper
│   ├── SDK (204 LOC)            # SDK abstraction
│   └── Builder (206 LOC)        # Build command wrapper
│
├── Project/                      # Project auto-detection
│   └── Detector (135 LOC)       # Scheme extraction
│
├── Utils/                        # Utilities
│   ├── Logger (92 LOC)          # Colored CLI output
│   ├── Spinner (41 LOC)         # Progress indicators
│   └── Template (84 LOC)        # File templating
│
├── Errors (49 LOC)              # Custom error hierarchy
└── Version (6 LOC)              # Version constant
```

**Total: 11 layers, 25+ classes, 4,645 LOC**

---

## Design Patterns Used

### 1. Factory Pattern
**Location:** `Platform::Registry`
```ruby
Platform::Registry.create('ios')           # → Platform::IOS instance
Platform::Registry.create_all(['ios', ...]) # → [instance, ...]
```
Creates platform instances without exposing implementation.

### 2. Builder Pattern
**Location:** `Builder::Orchestrator`
```ruby
# Multi-step build: Clean → Archive → XCFramework
Orchestrator.new(config).build
```
Each step returns hash with `:success`, error, and step-specific data.

### 3. Strategy Pattern
**Location:** `Config::Loader`, `CLI::Commands::Build`
```ruby
# Loading: File lookup → YAML/JSON parsing → Validation → Defaults
config = Config::Loader.load(config_file)
```

### 4. Template Method
**Location:** `Platform::Base`, `Builder::*`
Defines interface; subclasses implement specifics.

### 5. Registry Pattern
**Location:** `Swift::SDK`
```ruby
Swift::SDK.sdks_for_platform('ios')
  → [SDK(:iphoneos, 'arm64')]
```
Maps platforms to compiler SDKs.

---

## Build Pipelines

### Xcode Build Flow (Complete ✅)
```
1. CLI Input
   ↓
2. Config Validation (Loader → Schema)
   ↓
3. Clean Phase (optional)
   ├── Remove old archives
   ├── Clean XCFramework
   └── Clean derived data
   ↓
4. Archive Phase (per platform)
   ├── Get Platform instance
   ├── Merge build settings
   ├── xcodebuild archive
   └── Clean private interfaces
   ↓
5. XCFramework Phase
   ├── Locate frameworks
   ├── Include debug symbols
   └── xcodebuild -create-xcframework
   ↓
6. Result Output
```

### SPM Build Flow (Complete ✅)
```
1. Parse Package.swift
   ↓
2. For each SDK:
   ├── swift build --triple
   ├── Create framework structure
   ├── libtool binary compilation
   ├── Headers + modules
   └── Resource bundle copy
   ↓
3. For each platform:
   ├── Group slices by SDK
   ├── lipo combine architectures
   └── Create fat binaries
   ↓
4. XCFramework Assembly
```

---

## Configuration System

### File Discovery (Auto-Detection)
1. `.xcframework.yml` (first found)
2. `.xcframework.yaml`
3. `xcframework.yml`
4. `xcframework.yaml`
5. `.xcframework.json`
6. `xcframework.json`

### Validation Schema
Uses `dry-validation` for declarative rules:
- Project validation (xcode_project or spm)
- Platform validation (ios, ios-simulator, etc.)
- Architecture validation per platform
- Build settings type checking

### Default Values Applied
```yaml
build:
  output_dir: build/          # if missing
  configuration: Release       # if missing
  clean_before_build: false    # if missing
  verbose: false               # if missing
```

---

## Error Handling Strategy

### Error Hierarchy
```
Error (base)
├── ConfigError
│   ├── ValidationError      # Invalid config/args
│   └── FileNotFoundError    # Missing files
├── BuildError
│   ├── XcodebuildError      # xcodebuild failures
│   ├── ArchiveError         # Archive creation
│   └── XCFrameworkError     # Assembly failures
├── PlatformError
│   ├── UnsupportedPlatformError
│   └── InvalidArchitectureError
├── ResourceError
│   ├── BundleNotFoundError
│   └── InjectionError
└── PublishError
```

### User-Friendly Suggestions
```ruby
raise ValidationError.new(
  "Invalid platform: ios-macos",
  suggestions: [
    "Use 'ios' or 'ios-simulator'",
    "Run 'xckit platforms' to see options"
  ]
)
```

---

## Key Classes & Responsibilities

### CLI Layer
| Class | Purpose | Key Methods |
|-------|---------|-------------|
| `Runner` | Command dispatch | `build`, `spm`, `init` |
| `Commands::Build` | Xcode project builds | `execute`, `load_config` |
| `Commands::SPM` | SPM builds | `execute`, `run_build` |
| `Commands::Init` | Config generation | `execute`, `detect_project` |

### Builder Layer
| Class | Purpose | Key Methods |
|-------|---------|-------------|
| `Orchestrator` | Pipeline coordinator | `build`, `clean`, `archive` |
| `Archiver` | Archive creation | `archive_all`, `clean_archive` |
| `Cleaner` | Cleanup | `clean_all`, `remove_archives` |
| `XCFramework` | Assembly | `create_xcframework` |

### Platform Layer
| Class | Purpose | Key Methods |
|-------|---------|-------------|
| `Base` | Abstract interface | `platform_name`, `sdk_name` |
| `IOS` | iOS device | (inherits all from Base) |
| `IOSSimulator` | iOS Simulator | (inherits all from Base) |
| `Registry` | Factory | `create`, `create_all` |

---

## Testing Structure

### Organization
- **Unit Tests:** `spec/unit/` (mirror source structure)
- **Integration Tests:** `spec/integration/` (end-to-end CLI)
- **Test Config:** `spec_helper.rb` (SimpleCov, RSpec setup)

### Coverage by Module
| Module | Tests | Coverage |
|--------|-------|----------|
| Builder | 65+ | 85-95% |
| Platform | 35+ | 95%+ |
| Config | 15+ | 90%+ |
| CLI | 30+ | 80-85% |
| Xcodebuild | 30+ | 85%+ |
| SPM | 80+ | 80%+ |
| Utils | 15+ | 85%+ |

### Mocking Patterns
1. **Double Stubbing** - External dependencies
2. **Class Method Mocking** - Wrapper classes
3. **Filesystem Stubbing** - File operations
4. **Shell Command Mocking** - Open3 capture
5. **Block Yield Testing** - Directory operations

**Coverage Requirement:** 80% minimum (enforced by SimpleCov)

---

## Data Flow Examples

### Xcode Project Build
```
CLI::Commands::Build
  ↓
Config::Loader.load(.xcframework.yml)
  ↓
Config::Schema.call(config_hash) → validates
  ↓
Builder::Orchestrator.new(config).build
  ├→ Clean phase
  │  ↓
  │  Builder::Cleaner.clean_all
  │  ↓
  │  remove old .xcarchive + .xcframework
  │
  ├→ Archive phase
  │  ↓
  │  Platform::Registry.create_all(['ios', 'ios-simulator'])
  │  ↓
  │  Builder::Archiver.archive_all(platforms)
  │  ├→ For each platform:
  │  │  ├ xcodebuild archive
  │  │  ├ Xcodebuild::Wrapper.execute_archive
  │  │  └ Open3.capture3 + streaming
  │  │
  │  └→ Return archives hash
  │
  └→ XCFramework phase
     ↓
     Builder::XCFramework.create_xcframework(archives)
     ↓
     xcodebuild -create-xcframework ...
     ↓
     Xcodebuild::Wrapper.execute_create_xcframework
```

---

## Key Dependencies

### Runtime (Production)
- **thor** (v1.2+) - CLI framework
- **dry-validation** (v1.8+) - Schema validation
- **colorize** (v0.8+) - Terminal colors
- **tty-spinner** (v0.9+) - Progress indicators

### Development Only
- **rspec** (v3.x) - Testing
- **simplecov** - Coverage enforcement
- **pry** - Debugging
- **rubocop** - Linting

### External Tools
- **xcodebuild** - Xcode build system
- **swift** - Swift compiler
- **xcrun** - Xcode utilities
- **xcbeautify** or **xcpretty** - Output formatting (optional)
- **libtool** - Static library creation
- **lipo** - Binary architecture combining

---

## Extension Points

### Adding a New Platform (3 methods)
```ruby
class Platform::macOS < Base
  def self.platform_name; 'macOS'; end
  def self.platform_identifier; 'macos'; end
  def self.sdk_name; 'macosx'; end
  def self.destination; 'generic/platform=macOS'; end
  def self.valid_architectures; %w[arm64 x86_64]; end
  def self.default_deployment_target; '11.0'; end
end
```

### Adding Config Options
1. Update `Config::Schema` validation rules
2. Update `Config::Defaults` with defaults
3. Use in builder via `config[:build][:key]`

### Adding Build Steps
1. Create `Builder::YourStep` class
2. Implement action method returning `{ success: bool, ... }`
3. Integrate into `Orchestrator#build`
4. Add unit tests

---

## File Size Reference

### Implementation Files (lib/)
- Largest: `SPM::FrameworkSlice` (495 LOC)
- Largest: `Orchestrator` (318 LOC)
- Medium: `Package`, `XCFrameworkBuilder`, `Wrapper` (~300 LOC)
- Average: 150 LOC per file
- Smallest: `Version` (6 LOC)

### Test Files (spec/)
- Similar structure, well-balanced
- 280+ test examples
- Comprehensive mocking

---

## Quality Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Total LOC (impl) | 4,645 | ✅ |
| Total LOC (tests) | 4,419 | ✅ |
| Test/Code Ratio | 0.95 | ✅ |
| Modules | 11 layers | ✅ |
| Classes | 25+ | ✅ |
| Coverage | 85%+ | ✅ |
| Rubocop Issues | 0 | ✅ |

---

## Recent Changes (Phase 1)

- ✅ Completed iOS/iOS Simulator platform implementations
- ✅ Full SPM build pipeline (Package parsing to XCFramework)
- ✅ Xcode project pipeline (archive to XCFramework)
- ✅ Resource bundle detection and handling
- ✅ Comprehensive error handling with suggestions
- ✅ 280+ test cases with 80%+ coverage

---

## Next Steps (Phase 2)

1. Platform expansion (macOS, tvOS, watchOS, etc.)
2. Resource bundle automation
3. Publishing pipeline integration
4. Performance optimization and caching

