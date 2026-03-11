---
title: System Design
parent: Architecture
nav_order: 2
---

# XCFramework CLI - System Architecture

**Last Updated:** February 15, 2026
**Architecture Pattern:** Layered + Factory
**Build Systems Supported:** Xcode projects, Swift Packages

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface Layer                  │
│              CLI::Runner (Thor Commands)                 │
│           build / spm / init / version / help            │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│               Commands Layer                             │
│  Build / SPM / Init                                      │
│  • Load configuration or parse CLI args                  │
│  • Validate input parameters                             │
│  • Delegate to orchestrator                              │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│          Configuration Management Layer                  │
│  Config::Loader → Schema::Validator → Defaults          │
│  • YAML/JSON file discovery and parsing                 │
│  • Dry-validation schema enforcement                    │
│  • Default value application                            │
└────────────────────┬────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│            Build Orchestration Layer                     │
│        Builder::Orchestrator                             │
│  • Coordinates Clean → Archive → XCFramework            │
│  • Aggregates errors and results                        │
│  • Delegates to specialized builders                    │
└────────────────────┬────────────────────────────────────┘
         ┌───────────┼───────────┬──────────────┐
         ↓           ↓           ↓              ↓
    ┌────────┐ ┌─────────┐ ┌──────────┐ ┌───────────┐
    │ Clean  │ │ Archive │ │XCFramework│ │SPM Builder│
    │ Phase  │ │ Phase   │ │ Assembly  │ │           │
    └────────┘ └─────────┘ └──────────┘ └───────────┘
         │           │           │              │
         └───────────┼───────────┴──────────────┘
                     ↓
┌─────────────────────────────────────────────────────────┐
│     Platform Abstraction & Tool Integration Layer       │
│                                                          │
│  ┌─────────────────┐  ┌──────────────────────┐         │
│  │ Platform::Base  │  │ Xcodebuild::Wrapper  │         │
│  ├─────────────────┤  ├──────────────────────┤         │
│  │ IOS             │  │ execute_archive      │         │
│  │ IOSSimulator    │  │ execute_create_xcfw  │         │
│  └─────────────────┘  │ execute_clean        │         │
│                       └──────────────────────┘         │
│                                                          │
│  ┌─────────────────┐  ┌──────────────────────┐         │
│  │ Swift::SDK      │  │ SPM::Package         │         │
│  │ Swift::Builder  │  │ SPM::FrameworkSlice  │         │
│  │                 │  │ SPM::XCFrameworkBldR │         │
│  └─────────────────┘  └──────────────────────┘         │
└─────────────────────────────────────────────────────────┘
         │           │           │              │
         ↓           ↓           ↓              ↓
    ┌─────────────────────────────────────────────┐
    │     External Tools (via Open3)               │
    │  xcodebuild  swift  xcrun  libtool  lipo    │
    └─────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### 1. CLI Layer (thor)
**Files:** `cli/runner.rb`, `cli/commands/*.rb`

Responsibilities:
- Parse command-line arguments
- Dispatch to appropriate command
- Handle global options (verbose, quiet)
- Display results to user
- Catch and display errors with suggestions

Key Classes:
- `CLI::Runner` - Thor command dispatcher
- `CLI::Commands::Build` - Xcode project builds
- `CLI::Commands::SPM` - Swift Package builds
- `CLI::Commands::Init` - Config generation

### 2. Configuration Layer
**Files:** `config/loader.rb`, `config/schema.rb`, `config/defaults.rb`

Responsibilities:
- Discover configuration files (auto-detection)
- Parse YAML/JSON configuration
- Validate against schema using dry-validation
- Apply default values
- Raise helpful errors for invalid configs

Data Flow:
```
Raw YAML/JSON → Loader.load → Schema.validate → Defaults.apply → Config Hash
```

### 3. Build Orchestration Layer
**Files:** `builder/orchestrator.rb`, `builder/*.rb`

Responsibilities:
- Coordinate multi-step build pipeline
- Track success/failure of each step
- Aggregate error messages
- Return results to CLI for display

Pipeline Steps (Xcode):
1. Clean (optional) - remove old artifacts
2. Archive - create .xcarchive per platform
3. XCFramework - assemble from archives

Pipeline Steps (SPM):
1. Parse Package.swift
2. Build framework slices per SDK
3. Combine architectures
4. Assemble XCFramework

### 4. Platform Abstraction Layer
**Files:** `platform/base.rb`, `platform/ios.rb`, `platform/ios_simulator.rb`, `platform/registry.rb`

Responsibilities:
- Define platform-specific constants
- Provide SDK names and architectures
- Generate platform-specific build settings
- Support platform discovery

Design Pattern: **Template Method**
```ruby
class Platform::Base
  # These must be implemented by subclasses
  def self.platform_name; raise NotImplementedError; end
  def self.platform_identifier; raise NotImplementedError; end
  def self.sdk_name; raise NotImplementedError; end
  def self.destination; raise NotImplementedError; end
  def self.valid_architectures; raise NotImplementedError; end
  def self.default_deployment_target; raise NotImplementedError; end
end
```

Factory Pattern:
```ruby
Platform::Registry.create('ios')          # → iOS instance
Platform::Registry.create_all(['ios', ...]) # → [instances]
```

### 5. Xcodebuild Integration Layer
**Files:** `xcodebuild/wrapper.rb`, `xcodebuild/result.rb`, `xcodebuild/formatter.rb`

Responsibilities:
- Execute xcodebuild commands
- Capture stdout/stderr
- Parse success/failure
- Format output with xcbeautify/xcpretty
- Handle timeouts and interruptions

Key Methods:
- `Wrapper.execute_archive` - Create .xcarchive
- `Wrapper.execute_create_xcframework` - Assemble XCFramework
- `Wrapper.execute_clean` - Clean build artifacts

### 6. Swift Package Integration Layer
**Files:** `spm/package.rb`, `spm/framework_slice.rb`, `spm/xcframework_builder.rb`

Responsibilities:
- Parse Package.swift manifest
- Build framework slices for specific SDKs
- Create framework structure
- Combine multi-architecture binaries
- Handle resource bundles

Key Methods:
- `Package.load` - Parse Package.swift
- `FrameworkSlice.build` - Build single SDK slice
- `XCFrameworkBuilder.build` - Multi-SDK aggregation

### 7. Utility Layers
**Files:** `utils/logger.rb`, `utils/spinner.rb`, `utils/template.rb`

Responsibilities:
- Provide colored console output (Logger)
- Show progress spinners (Spinner)
- Generate files from templates (Template)

---

## Data Flow - Xcode Build

```
User Input
    │
    ↓
CLI::Commands::Build.execute
    ├─ Load config OR parse CLI args
    ├─ Validate input parameters
    │
    └─→ Builder::Orchestrator.new(config).build
           │
           ├─ CLEAN PHASE
           │  ├─ Builder::Cleaner.clean_all
           │  │  ├─ Find old archives: Dir.glob('build/*.xcarchive')
           │  │  ├─ Remove: FileUtils.rm_rf
           │  │  └─ Clean derived data: xcrun -rs
           │  │
           │  └─ Result: { success: bool, ... }
           │
           ├─ ARCHIVE PHASE
           │  ├─ Platform::Registry.create_all(platforms)
           │  │  └─ [Platform::IOS, Platform::IOSSimulator]
           │  │
           │  ├─ For each platform:
           │  │  ├─ Merge build settings
           │  │  ├─ Xcodebuild::Wrapper.execute_archive(
           │  │  │    project, scheme, sdk, destination, ...
           │  │  │  )
           │  │  ├─ Open3.capture3(xcodebuild command)
           │  │  ├─ Stream output through formatter
           │  │  └─ Verify archive exists
           │  │
           │  └─ Result: { success: bool, archives: {...} }
           │
           └─ XCFRAMEWORK PHASE
              ├─ Builder::XCFramework.create_xcframework
              ├─ Locate frameworks in archives
              ├─ Xcodebuild::Wrapper.execute_create_xcframework(
              │    -create-xcframework
              │    -framework <path to framework>
              │    -output <xcframework path>
              │  )
              └─ Result: { success: bool, xcframework_path: '...' }

Output: { success: bool, error: nil, xcframework_path: '...' }
    │
    └─→ Display to user via Logger
```

---

## Data Flow - SPM Build

```
User Input
    │
    ↓
CLI::Commands::SPM.execute
    ├─ Load config OR parse CLI args
    ├─ Validate package_dir exists
    │
    └─→ SPM::Package.load(package_dir)
           ├─ swift package dump-package
           ├─ JSON.parse output
           ├─ Extract targets, platforms
           │
           └─ Result: { targets: [...], platforms: [...] }
                │
                ↓
    SPM::XCFrameworkBuilder.new(config).build
           │
           ├─ For each SDK (mapped from platforms):
           │  ├─ SPM::FrameworkSlice.build(sdk)
           │  │  ├─ swift build --triple arm64-apple-ios15.0
           │  │  ├─ Create framework structure
           │  │  ├─ libtool combine objects
           │  │  ├─ Generate headers + modules
           │  │  └─ Copy resource bundle
           │  │
           │  └─ Result: { binary: path, headers: [...] }
           │
           ├─ For each platform (group slices):
           │  ├─ Group SDKs by platform
           │  ├─ lipo combine architectures
           │  │    lipo -create arm64 x86_64 -output fat_binary
           │  │
           │  └─ Result: { binary: path_to_fat }
           │
           └─ XCFramework assembly
              ├─ xcodebuild -create-xcframework
              └─ Result: { xcframework_path: '...' }

Output: { success: bool, xcframework_path: '...' }
    │
    └─→ Display to user via Logger
```

---

## Configuration Schema

```yaml
project:                          # Xcode project (mutually exclusive with spm)
  name: String                    # Framework name
  xcode_project: String           # Path to .xcodeproj

spm:                              # Swift Package (mutually exclusive with project)
  package_dir: String             # Root directory
  targets: [String]               # Target names to build
  platforms: [String]             # Platforms to build
  library_evolution: Boolean      # ABI stability
  version: String                 # Minimum version

frameworks:                       # Array of framework configs
  - name: String
    scheme: String
    platforms: [String]           # e.g., [ios, ios-simulator]
    architectures: {String: [String]}  # Override per platform
    deployment_targets: {String: String}  # Override per platform

build:                           # Build configuration
  output_dir: String             # Where to put .xcframework
  configuration: 'Debug'|'Release'
  clean_before_build: Boolean
  verbose: Boolean
  use_formatter: Boolean         # Use xcbeautify/xcpretty
  build_settings: {String: String}  # Custom xcodebuild settings

publishing:                      # Optional publishing config
  artifactory_url: String
  git_branch: String
```

---

## Error Handling Architecture

### Error Hierarchy
```
StandardError
    └─ XCFrameworkCLI::Error
        ├─ ConfigError
        │  ├─ ValidationError
        │  └─ FileNotFoundError
        ├─ BuildError
        │  ├─ XcodebuildError
        │  ├─ ArchiveError
        │  └─ XCFrameworkError
        ├─ PlatformError
        │  ├─ UnsupportedPlatformError
        │  └─ InvalidArchitectureError
        ├─ ResourceError
        │  ├─ BundleNotFoundError
        │  └─ InjectionError
        └─ PublishError
```

### Error Flow
```
Error raised in builder/validator/platform
    │
    ├─ Include helpful suggestions
    │    raise ValidationError.new(
    │      "Invalid platform",
    │      suggestions: ["Use 'ios'", "Run 'xckit platforms'"]
    │    )
    │
    └─ Caught in CLI::Commands
       │
       ├─ Logger.error(message)
       ├─ Display suggestions
       └─ exit 1
```

---

## Extension Points

### Adding a New Platform

**Step 1:** Create platform class (4-6 methods)
```ruby
# lib/xcframework_cli/platform/macos.rb
class Platform::macOS < Base
  def self.platform_name; 'macOS'; end
  def self.platform_identifier; 'macos'; end
  def self.sdk_name; 'macosx'; end
  def self.destination; 'generic/platform=macOS'; end
  def self.valid_architectures; %w[arm64 x86_64]; end
  def self.default_deployment_target; '11.0'; end
  def self.default_architectures; { 'macos' => %w[arm64 x86_64] }; end
end
```

**Step 2:** Register in platform registry
```ruby
# lib/xcframework_cli/platform/registry.rb
PLATFORMS = {
  'ios' => IOS,
  'ios-simulator' => IOSSimulator,
  'macos' => macOS,  # Add this
}
```

**Step 3:** Add to schema (already done - 10 platforms defined)
**Step 4:** Create tests
```ruby
# spec/unit/platform/macos_spec.rb
RSpec.describe XCFrameworkCLI::Platform::macOS do
  # Test all class methods
end
```

### Adding a Build Step

**Step 1:** Create step class
```ruby
# lib/xcframework_cli/builder/my_step.rb
class Builder::MyStep
  def initialize(config)
    @config = config
  end

  def execute
    # Do work
    { success: true, data: result }
  rescue StandardError => e
    { success: false, error: e.message }
  end
end
```

**Step 2:** Integrate into orchestrator
```ruby
# In orchestrator.build
my_step = Builder::MyStep.new(@config)
result = my_step.execute
return result unless result[:success]
```

**Step 3:** Test it
```ruby
# spec/unit/builder/my_step_spec.rb
describe Builder::MyStep do
  # Mock dependencies, test execute
end
```

---

## Performance Characteristics

| Operation | Typical Time | Notes |
|-----------|--------------|-------|
| Config loading | < 100ms | YAML parsing + validation |
| iOS archive | 60-120s | xcodebuild + copying |
| iOS Simulator archive | 45-90s | Usually faster than device |
| XCFramework assembly | 5-10s | xcodebuild -create-xcframework |
| **Total Xcode build** | **2-3 minutes** | Both platforms + assembly |
| SPM package parsing | < 500ms | swift package dump-package |
| SPM slice build | 30-60s per arch | swift build + framework creation |
| **Total SPM build** | **2-4 minutes** | Multiple SDKs + assembly |

---

## Dependencies Map

```
XCFrameworkCLI (main module)
    │
    ├─ thor (CLI framework)
    ├─ dry-validation (configuration validation)
    ├─ colorize (terminal colors)
    ├─ tty-spinner (progress indicators)
    │
    └─ stdlib
       ├─ json (JSON parsing)
       ├─ yaml (YAML parsing)
       ├─ open3 (shell command execution)
       ├─ fileutils (file operations)
       └─ tmpdir (temporary directories)
```

**Total runtime gems:** 4
**External tool requirements:** xcodebuild, swift, xcrun, optionally xcbeautify

---

## Testing Architecture

### Test Organization
```
spec/
├─ spec_helper.rb              # SimpleCov, RSpec config
├─ integration_helper.rb       # Integration test setup
├─ unit/
│  ├─ cli/
│  ├─ builder/
│  ├─ config/
│  ├─ platform/
│  ├─ xcodebuild/
│  ├─ spm/
│  ├─ swift/
│  └─ utils/
└─ integration/
   └─ cli_build_spec.rb        # End-to-end tests
```

### Test Isolation Strategy
- Mock external commands (xcodebuild, swift)
- Stub filesystem operations
- Use instance doubles for dependencies
- Suppress logger output in tests
- Temp directories auto-cleaned

### Coverage Targets
- Builder layer: 85-95%
- Platform layer: 95%+
- Config layer: 90%+
- CLI layer: 80%+
- Overall: 80%+ (enforced)

---

## Deployment Model

XCFramework CLI is distributed as a Ruby gem:

```
Gem::Specification.new do |spec|
  spec.name = 'xcframework-cli'
  spec.version = XCFrameworkCLI::VERSION
  spec.platform = 'ruby'
  spec.required_ruby_version = '>= 3.0'

  spec.executables = ['xckit']
  spec.files = Dir['lib/**/*.rb'] + Dir['bin/**/*']
end
```

Users install via:
```bash
gem install xcframework-cli
# or from Gemfile
gem 'xcframework-cli'
```

Binary entry point: `bin/xckit` → CLI::Runner

---

## Future Scalability

For Phase 2-5 expansion:

1. **Platform additions** - 50 LOC per platform, factory already extensible
2. **Resource management** - New `Builder::ResourceManager` step
3. **Publishing** - New `Builder::Publisher` + `Publish::Artifactory`
4. **Caching** - New `Builder::Cache` layer to skip unchanged builds
5. **Parallel builds** - Refactor orchestrator to use threads/processes

Current architecture supports all without major restructuring.

