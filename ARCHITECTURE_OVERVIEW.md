# XCFramework CLI - Architecture Overview

**Visual guide to the Ruby implementation architecture**

---

## 🏛️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         CLI Layer                            │
│  (Thor-based command interface: build, publish, init, etc.) │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Configuration Layer                        │
│  (YAML/JSON loading, validation, environment variables)     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Orchestration Layer                        │
│         (Build pipeline, workflow management)                │
└───┬──────────┬──────────┬──────────┬──────────┬────────────┘
    │          │          │          │          │
    ▼          ▼          ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│Platform│ │Builder │ │Resource│ │Xcode   │ │Publish │
│        │ │        │ │Manager │ │build   │ │        │
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘
```

---

## 📦 Module Breakdown

### 1. CLI Module (`lib/xcframework_cli/cli.rb`)

**Responsibilities**:
- Command routing (build, publish, init, clean, validate)
- Argument parsing
- Help documentation
- User interaction

**Key Commands**:
```
build       - Build XCFrameworks
publish     - Publish to Artifactory
init        - Interactive setup wizard
clean       - Clean build artifacts
validate    - Validate configuration
platforms   - List supported platforms
```

---

### 2. Configuration Module (`lib/xcframework_cli/config/`)

**Components**:
```
config/
├── loader.rb       # Load YAML/JSON config files
├── validator.rb    # Validate against schema
├── schema.rb       # Define configuration schema
├── defaults.rb     # Default values
└── env_loader.rb   # Environment variable support
```

**Configuration Flow**:
```
Environment Variables → Config File → Defaults → Validation → Merged Config
```

**Example Config Structure**:
```yaml
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"

frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms: [ios, ios-simulator, macos]
    
build:
  output_dir: "build"
  xcframework_output: "../SDKs"
```

---

### 3. Platform Module (`lib/xcframework_cli/platform/`)

**Platform Hierarchy**:
```
Platform::Base (abstract)
├── Platform::IOS
├── Platform::IOSSimulator
├── Platform::MacOS
├── Platform::Catalyst
├── Platform::TVOS
├── Platform::TVOSSimulator
├── Platform::WatchOS
├── Platform::WatchOSSimulator
├── Platform::VisionOS
└── Platform::VisionOSSimulator
```

**Platform Attributes**:
- `name` - Human-readable name
- `sdk` - SDK identifier (iphoneos, iphonesimulator, etc.)
- `destination` - xcodebuild destination string
- `supported_archs` - Supported architectures
- `target_os` - Target OS for compilation

**Platform Registry**:
```ruby
Platform::Registry.all
# => [IOS, IOSSimulator, MacOS, ...]

Platform::Registry.find('ios')
# => Platform::IOS

Platform::Registry.valid?('ios')
# => true
```

---

### 4. Builder Module (`lib/xcframework_cli/builder/`)

**Build Pipeline**:
```
┌──────────┐
│ Cleaner  │ Clean previous builds (optional)
└────┬─────┘
     │
     ▼
┌──────────┐
│ Archiver │ Build archives for each platform
└────┬─────┘
     │
     ▼
┌──────────┐
│ Resource │ Copy resource bundles
│ Manager  │ Inject custom accessors
└────┬─────┘
     │
     ▼
┌──────────┐
│XCFramework│ Assemble XCFramework from archives
└────┬─────┘
     │
     ▼
┌──────────┐
│ Checksum │ Generate SHA256 (optional)
└──────────┘
```

**Components**:
- `Orchestrator` - Coordinates entire build process
- `Archiver` - Creates .xcarchive for each platform
- `XCFramework` - Assembles final .xcframework
- `Cleaner` - Cleans build artifacts

---

### 5. Resource Module (`lib/xcframework_cli/resource/`)

**Resource Management Flow**:
```
1. Discover resource bundles in build artifacts
   ↓
2. Copy bundles into framework directory
   ↓
3. Find SPM's resource_bundle_accessor.swift
   ↓
4. Render custom template with variables
   ↓
5. Replace accessor file
   ↓
6. Recompile .o file with swiftc
```

**Components**:
- `Manager` - Bundle discovery and copying
- `AccessorInjector` - Swift file injection
- `TemplateEngine` - ERB template rendering

**Template Variables**:
```erb
<%= bundle_name %>          # Resource bundle name
<%= framework_name %>       # Framework name
<%= module_name %>          # Module name
<%= search_paths %>         # Custom search paths
```

---

### 6. Xcodebuild Module (`lib/xcframework_cli/xcodebuild/`)

**xcodebuild Wrapper**:
```ruby
Xcodebuild::Wrapper.execute(
  command: :archive,
  project: "MyProject.xcodeproj",
  scheme: "MySDK",
  destination: "generic/platform=iOS",
  archive_path: "build/MySDK-iOS.xcarchive",
  build_settings: {
    BUILD_LIBRARY_FOR_DISTRIBUTION: 'YES',
    ARCHS: 'arm64',
    SKIP_INSTALL: 'NO'
  }
)
```

**Components**:
- `Wrapper` - Execute xcodebuild commands
- `Formatter` - Format output (xcbeautify/xcpretty)
- `ErrorParser` - Parse and enhance error messages

---

### 7. Publisher Module (`lib/xcframework_cli/publisher/`)

**Publishing Flow**:
```
1. Git Tagger
   - Create version tag
   - Push to remote
   ↓
2. Artifactory Publisher
   - Login to Artifactory
   - Publish XCFramework
   ↓
3. Notifier
   - Send Slack notification
   - Include changelog
```

**Components**:
- `GitTagger` - Git tagging and versioning
- `Artifactory` - JFrog/Artifactory publishing
- `Notifier` - Slack/webhook notifications

---

## 🔄 Data Flow

### Build Command Flow

```
User runs: xcframework-cli build MySDK --platforms ios,macos
                    │
                    ▼
            ┌───────────────┐
            │  CLI Parser   │
            └───────┬───────┘
                    │
                    ▼
            ┌───────────────┐
            │ Config Loader │ Load .xcframework.yml
            └───────┬───────┘
                    │
                    ▼
            ┌───────────────┐
            │  Validator    │ Validate config
            └───────┬───────┘
                    │
                    ▼
            ┌───────────────┐
            │ Orchestrator  │ Coordinate build
            └───────┬───────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
    ┌───────┐  ┌───────┐  ┌───────┐
    │  iOS  │  │ macOS │  │ ...   │ Build each platform
    └───┬───┘  └───┬───┘  └───┬───┘
        │          │          │
        └──────────┼──────────┘
                   ▼
           ┌───────────────┐
           │  XCFramework  │ Assemble
           └───────┬───────┘
                   │
                   ▼
           ┌───────────────┐
           │    Success    │ Report to user
           └───────────────┘
```

---

## 🎨 Design Patterns Used

### 1. Strategy Pattern
**Platform abstraction** - Each platform implements the same interface

### 2. Template Method Pattern
**Build pipeline** - Orchestrator defines steps, subclasses implement details

### 3. Factory Pattern
**Platform registry** - Create platform instances by name

### 4. Builder Pattern
**Configuration** - Build complex config objects step by step

### 5. Command Pattern
**CLI commands** - Each command is an object with execute method

---

## 🔌 Extension Points

### Custom Build Steps
```ruby
# User can add custom build steps
class MyCustomStep < XCFrameworkCLI::Builder::Step
  def execute(context)
    # Custom logic
  end
end

# Register step
XCFrameworkCLI::Builder::Pipeline.register_step(MyCustomStep)
```

### Custom Platforms
```ruby
# Add support for new platform
class CustomPlatform < XCFrameworkCLI::Platform::Base
  def self.platform_name
    'CustomOS'
  end
  # ... implement required methods
end

# Register platform
XCFrameworkCLI::Platform::Registry.register(CustomPlatform)
```

---

## 📊 Class Diagram (Simplified)

```
┌─────────────────┐
│      CLI        │
└────────┬────────┘
         │ uses
         ▼
┌─────────────────┐
│  Orchestrator   │
└────────┬────────┘
         │ uses
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│Platform│ │Builder │ │Resource│ │Publish │
│Registry│ │        │ │Manager │ │        │
└────────┘ └────────┘ └────────┘ └────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Platform::Base                  │
├─────────────────────────────────┤
│ + name                          │
│ + sdk                           │
│ + destination                   │
│ + supported_archs               │
├─────────────────────────────────┤
│ + sdk_path()                    │
│ + target_triple(arch, version)  │
└─────────────────────────────────┘
         △
         │ inherits
    ┌────┴────┬────────┬────────┐
    │         │        │        │
┌────────┐ ┌────────┐ ┌────────┐ ...
│  IOS   │ │ MacOS  │ │  TVOS  │
└────────┘ └────────┘ └────────┘
```

---

## 🚀 Performance Considerations

### Parallel Builds
```ruby
# Build platforms in parallel (optional)
orchestrator.build(framework, parallel: true)

# Uses Ruby threads or processes
platforms.map do |platform|
  Thread.new { build_archive(platform) }
end.each(&:join)
```

### Caching
- Incremental builds with `--no-clean`
- Reuse derived data
- Cache SDK paths

### Optimization
- Lazy loading of platforms
- Memoization of SDK paths
- Efficient file operations

---

## 🔒 Error Handling Strategy

### Error Hierarchy
```
Error (StandardError)
├── ConfigError
│   ├── ValidationError
│   └── FileNotFoundError
├── BuildError
│   ├── XcodebuildError
│   ├── ArchiveError
│   └── XCFrameworkError
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

### Error Recovery
- Cleanup on failure
- Rollback partial builds
- Helpful error messages with suggestions

---

**This architecture provides**:
- ✅ Modularity and separation of concerns
- ✅ Extensibility for new platforms
- ✅ Testability with clear interfaces
- ✅ Maintainability with clean code
- ✅ Performance with optional parallelization


