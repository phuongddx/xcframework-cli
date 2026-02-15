# XCFramework CLI - lib/ Directory Architecture Analysis

**Report Date:** February 15, 2026  
**Scope:** Complete analysis of 31 Ruby files in `lib/` directory (4,739 LOC)

---

## Executive Summary

XCFramework CLI is a well-architected Ruby gem demonstrating:

- **Clear module separation** with distinct layers (CLI, Config, Build, Platform, Xcodebuild, SPM, Swift)
- **Design patterns:** Factory, Registry, Builder, Strategy, Template Method
- **Two build pipelines:** Xcode projects (complete) and SPM (in development)
- **Configuration-driven:** YAML/JSON with dry-validation schema
- **Custom error hierarchy:** Domain-specific errors with user suggestions

**Key Stats:** 31 files, 4,645 LOC, 25+ core classes, 2 implemented platforms, 10 in schema

---

## Module Structure

### Top-Level Organization
```
XCFrameworkCLI (Main Module)
├── CLI Layer              # Command-line interface
├── Builder Layer          # Build orchestration
├── Config Layer           # Configuration management
├── Platform Layer         # Platform abstraction
├── Xcodebuild Layer       # Xcode integration
├── SPM Layer              # Swift Package support
├── Swift Layer            # Swift compiler wrapper
├── Project Layer          # Auto-detection
├── Utils Layer            # Utilities & helpers
├── Errors                 # Custom error hierarchy
└── Version                # Version constant
```

### Layer Details

#### 1. CLI Layer (`cli/`)
- **Runner** (220 LOC) - Thor-based command dispatcher
  - Commands: build, spm, init, version, help
  - Global options: -v/--verbose, -q/--quiet
  - Error handling with suggestions

- **Commands::Build** (182 LOC) - Xcode project builds
  - Config file or CLI arguments
  - Validation of required parameters
  - Orchestrator integration
  - Result display with archive listing

- **Commands::SPM** (127 LOC) - Swift Package builds
  - Target selection
  - Platform configuration
  - Config file support
  - Result reporting

- **Commands::Init** (181 LOC) - Configuration generation
  - Project type detection (SPM vs Xcode)
  - Metadata extraction
  - Template-based config generation
  - YAML/JSON output

#### 2. Config Layer (`config/`)
- **Loader** (132 LOC) - File parsing & discovery
  - Auto-detection: .xcframework.yml, .xcframework.yaml, etc.
  - YAML/JSON parsing with error handling
  - Validation via Schema contract
  - Default application

- **Schema** (127 LOC) - Dry-validation contract
  - Xcode project validation
  - SPM configuration validation
  - Platform & architecture validation
  - Build settings validation
  - 10 platforms defined but only iOS variants implemented

- **Defaults** (104 LOC) - Default values
  - Build defaults: output_dir, configuration, verbose, etc.
  - Deployment targets per platform
  - Default architectures per platform
  - Publishing defaults

- **Generator** (125 LOC) - Template generation
  - SPM config template
  - Xcode config template
  - YAML/JSON output

#### 3. Builder Layer (`builder/`)
- **Orchestrator** (318 LOC) - Main pipeline coordinator
  - Full build pipeline: clean → archive → xcframework
  - SPM build pipeline
  - Step-by-step execution
  - Error aggregation

- **Archiver** (188 LOC) - Archive creation
  - Platform-specific builds
  - xcodebuild integration
  - Build settings management
  - Archive verification
  - Private interface cleanup

- **Cleaner** (147 LOC) - Artifact management
  - Archive cleanup patterns
  - XCFramework removal
  - Derived data cleanup
  - Output directory management

- **XCFramework** (173 LOC) - XCFramework assembly
  - Archive verification
  - Framework location
  - dSYM inclusion
  - xcodebuild -create-xcframework execution

#### 4. Platform Layer (`platform/`)
- **Base** (147 LOC) - Abstract interface
  - platform_name, platform_identifier
  - sdk_name, destination
  - valid_architectures, default_deployment_target
  - build_settings generation
  - SDK path resolution

- **IOS** (42 LOC) - iOS device
  - arm64 only
  - iphoneos SDK
  - IPHONEOS_DEPLOYMENT_TARGET

- **IOSSimulator** (42 LOC) - iOS Simulator
  - arm64 and x86_64
  - iphonesimulator SDK
  - Multi-architecture support

- **Registry** (96 LOC) - Factory pattern
  - Platform creation by identifier
  - Validation helpers
  - Platform information queries
  - Batch creation support

#### 5. Xcodebuild Layer (`xcodebuild/`)
- **Wrapper** (167 LOC) - Command orchestrator
  - execute_archive
  - execute_create_xcframework
  - execute_clean
  - Generic execute with streaming
  - Tool availability checks

- **Result** (51 LOC) - Result encapsulation
  - success?, failure? predicates
  - Combined stdout/stderr output
  - Error message extraction
  - Exit code tracking

- **Formatter** (189 LOC) - Output beautification
  - Formatter detection (xcbeautify, xcpretty)
  - Real-time piping
  - Multi-threaded streaming
  - Fallback modes

#### 6. SPM Layer (`spm/`)
- **Package** (315 LOC) - Package.swift parser
  - swift package dump-package integration
  - Target enumeration (library, executable, test, binary)
  - Platform version extraction
  - Resource bundle tracking

- **FrameworkSlice** (495 LOC) - Single SDK framework
  - Swift build execution
  - Framework structure creation
  - Binary via libtool
  - Headers and modules
  - Resource bundle handling
  - Private interface override

- **XCFrameworkBuilder** (313 LOC) - Multi-SDK aggregator
  - Platform-to-SDK mapping
  - Slice building
  - Architecture combining via lipo
  - XCFramework assembly

#### 7. Swift Layer (`swift/`)
- **SDK** (204 LOC) - SDK abstraction
  - Triple generation (arm64-apple-ios15.0-simulator)
  - SDK path resolution
  - Platform mapping
  - Compiler argument generation

- **Builder** (206 LOC) - Swift build wrapper
  - swift build command construction
  - SDK and triple handling
  - Configuration (debug/release)
  - Library evolution support
  - Multi-SDK building

#### 8. Project Layer (`project/`)
- **Detector** (135 LOC) - Auto-detection
  - SPM detection (Package.swift)
  - Xcode detection (.xcodeproj, .xcworkspace)
  - Scheme extraction via xcodebuild -list
  - Metadata extraction

#### 9. Utils Layer (`utils/`)
- **Logger** (92 LOC) - Colored CLI output
  - debug, info, success, warning, error
  - Verbose/quiet modes
  - Emoji support
  - Section headers and results

- **Spinner** (41 LOC) - Progress indication
  - TTY spinner wrapper
  - Multi-spinner support
  - Quiet mode handling

- **Template** (84 LOC) - File templating
  - Template file discovery
  - Variable substitution ({{KEY}} → value)
  - Framework.plist, modulemap generation

#### 10. Core Files
- **Errors** (49 LOC) - Error hierarchy
  - Base Error with suggestions
  - ConfigError, ValidationError, FileNotFoundError
  - BuildError, XcodebuildError, ArchiveError, XCFrameworkError
  - PlatformError, UnsupportedPlatformError, InvalidArchitectureError
  - ResourceError, PublishError

- **Version** (6 LOC) - Version constant (0.2.0)

---

## Design Patterns

### 1. Factory Pattern (Platform Registry)
```ruby
Platform::Registry.create('ios')            # → Platform::IOS instance
Platform::Registry.create_all(['ios', ...]) # → [IOS instance, ...]
```
Creates platform instances without exposing implementation.

### 2. Builder Pattern (Build Pipeline)
```ruby
Orchestrator.new(config).build              # Multi-step build
  → Clean → Archive → XCFramework
```
Each step independent; results aggregate errors.

### 3. Strategy Pattern (Config Loading)
```ruby
Commands::Build#load_configuration
  → Config file strategy
  → CLI arguments strategy
  → Command-line overrides
```

### 4. Template Method (Platform Interface)
```ruby
class Platform::Base
  # Define interface
  .platform_name, .sdk_name, .destination, etc.

class Platform::IOS < Base
  # Implement for iOS
end
```

### 5. Registry/Mapper (SDK Management)
```ruby
Swift::SDK.sdks_for_platform('ios')
  → [SDK(:iphoneos, 'arm64')]

.sdks_for_platform('ios-simulator')
  → [SDK(:iphonesimulator, 'arm64'), SDK(:iphonesimulator, 'x86_64')]
```

---

## Build Pipelines

### Xcode Pipeline (Complete)
```
1. Build Command Execution
   → Load config or CLI args
   → Validate required parameters
   
2. Clean Phase (optional)
   → Remove old archives
   → Clean XCFramework
   → Clean derived data
   
3. Archive Phase
   For each platform:
   → Get platform instance
   → Merge build settings
   → Execute xcodebuild archive
   → Clean private interfaces
   
4. XCFramework Phase
   → Locate frameworks in archives
   → Include debug symbols (optional)
   → Execute xcodebuild -create-xcframework
   → Return path
```

### SPM Pipeline (In Development)
```
1. Package Discovery
   → Parse Package.swift (swift package dump-package)
   → Extract targets and platforms
   
2. Framework Slice Building
   For each SDK:
   → Execute swift build --triple
   → Create framework structure
   → Compile binary with libtool
   → Create headers (umbrella + Swift headers)
   → Generate modules (modulemap, swiftmodule)
   → Copy resource bundle (if exists)
   
3. Multi-Architecture Combining
   For each platform:
   → Group slices by SDK name
   → Combine architectures with lipo
   → Create fat binaries
   
4. XCFramework Assembly
   → Execute xcodebuild -create-xcframework
   → Return path
```

---

## Configuration Schema

### Supported Keys
```yaml
project:                        # Xcode project
  name: String
  xcode_project: String
  
frameworks:                     # Array of frameworks
  - name: String
    scheme: String
    platforms: [String]
    architectures: Hash
    deployment_targets: Hash
    
spm:                           # Swift Package
  package_dir: String
  targets: [String]
  platforms: [String]
  library_evolution: Boolean
  
build:                         # Shared build config
  output_dir: String
  configuration: 'Debug' | 'Release'
  clean_before_build: Boolean
  verbose: Boolean
  build_settings: Hash         # Custom xcodebuild flags
  
publishing:                    # Publishing config
  artifactory_url: String
  git_branch: String
```

### Platform Coverage
- **Implemented (2):** ios, ios-simulator
- **Schema Defined (8):** macos, catalyst, tvos, tvos-simulator, watchos, watchos-simulator, visionos, visionos-simulator

### Default Values Applied
- iOS: arm64, deployment target 14.0
- iOS Simulator: arm64+x86_64, deployment target 14.0
- macOS: arm64+x86_64, deployment target 11.0
- tvOS: arm64, deployment target 14.0

---

## Error Handling Strategy

### Error Hierarchy
```
Error (base)
├── ConfigError
│   ├── ValidationError       # Invalid config/args
│   └── FileNotFoundError     # Missing files
├── BuildError
│   ├── XcodebuildError       # xcodebuild failures
│   ├── ArchiveError          # Archive creation failures
│   └── XCFrameworkError      # XCFramework assembly failures
├── PlatformError
│   ├── UnsupportedPlatformError
│   └── InvalidArchitectureError
├── ResourceError
│   ├── BundleNotFoundError
│   └── InjectionError
└── PublishError
    ├── ArtifactoryError
    └── GitError
```

### User-Friendly Suggestions
```ruby
raise ValidationError.new(
  "Invalid platform: ios-macos",
  suggestions: [
    "Use 'ios' or 'ios-simulator'",
    "Run 'xckit platforms' to see all options"
  ]
)

# Displayed to user as:
# Error: Invalid platform: ios-macos
# 
# Suggestions:
#   • Use 'ios' or 'ios-simulator'
#   • Run 'xckit platforms' to see all options
```

---

## Key Dependencies

### Gems
- `thor` - CLI framework (commands, options)
- `dry-validation` - Schema validation
- `colorize` - Terminal color output
- `tty-spinner` - Progress spinners

### External Tools Required
- `xcodebuild` - Xcode build system
- `xcrun` - Xcode utilities (SDK path resolution)
- `swift` - Swift compiler (SPM builds)
- `xcbeautify`/`xcpretty` - Build formatters (optional)
- `libtool` - Static library creation (SPM)
- `lipo` - Fat binary creation (SPM multi-arch)

---

## Strengths ✅

1. **Clear Module Boundaries** - Each layer has single responsibility
2. **Design Patterns** - Factory, Builder, Strategy appropriately applied
3. **Error Handling** - Custom errors with helpful suggestions
4. **Configuration-Driven** - Flexible without hardcoding
5. **Two Pipelines** - Separate optimized paths for Xcode and SPM
6. **Extensible** - New platforms need only 3 methods
7. **Logging** - Verbose/quiet modes, colored output
8. **No Tight Coupling** - Layers independent, swappable

---

## Areas for Improvement ⚠️

1. **Large Files** - Orchestrator (318 LOC), FrameworkSlice (495 LOC)
2. **Shell Execution** - Scattered; could consolidate patterns
3. **Duplication** - Build settings merged in Archiver AND Wrapper
4. **Platform Coverage** - 2 of 10 platforms implemented
5. **SPM Complexity** - Manual binary creation with libtool intricate
6. **Testing** - 80% coverage enforced but error paths not all covered
7. **Resource Bundles** - Template-based compilation is complex

---

## Extensibility

### Adding macOS Support
```ruby
# 1. Create lib/xcframework_cli/platform/macos.rb
class macOS < Base
  def self.platform_name; 'macOS'; end
  def self.platform_identifier; 'macos'; end
  def self.sdk_name; 'macosx'; end
  def self.destination; 'generic/platform=macOS'; end
  def self.valid_architectures; %w[arm64 x86_64]; end
  def self.default_deployment_target; '11.0'; end
  def sdk_version_key; 'MACOSX_DEPLOYMENT_TARGET'; end
end

# 2. Update platform/registry.rb
PLATFORMS = { 'macos' => macOS }

# 3. Add tests in spec/unit/platform/macos_spec.rb
```

### Adding Config Option
```ruby
# 1. config/schema.rb
optional(:my_option).filled(:string)

# 2. config/defaults.rb
MY_OPTION_DEFAULT = 'value'

# 3. Use in builder
config[:build][:my_option]
```

---

## Summary

XCFramework CLI demonstrates professional architecture with:

- Well-organized 11-layer module structure
- Design patterns appropriately applied
- Comprehensive error handling with user suggestions
- Two functional build pipelines (Xcode complete, SPM in progress)
- Configuration validation with dry-validation
- Platform abstraction for multi-platform support
- Clear separation of concerns throughout

The codebase is maintainable, extensible, and ready for Phase 2 expansion to additional platforms (macOS, tvOS, etc.).

**Report Generated:** 2026-02-15 13:45  
**Files Analyzed:** 31 Ruby files (4,645 LOC)  
**Analysis Method:** Complete file read and architecture review
