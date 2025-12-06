# XCFramework CLI - Refactoring Analysis & Implementation Plan
## Generic Ruby-Based XCFramework Builder

**Date**: December 6, 2025  
**Project**: `/Users/ddphuong/Projects/xcframework-cli`  
**Objective**: Transform existing Bash scripts into a generic, reusable Ruby CLI tool for creating XCFrameworks

---

## 📊 PART 1: CURRENT STATE ANALYSIS

### 1.1 Existing Project Structure

The project currently consists of **Bash scripts** (~1,653 lines) with comprehensive documentation:

```
xcframework-cli/
├── Bash Scripts (Production)
│   ├── config.sh                   (164 lines) - Centralized configuration
│   ├── create-xcframework.sh       (625 lines) - Core build logic
│   ├── debug.sh                    (144 lines) - Debug build wrapper
│   ├── release.sh                  (110 lines) - Release build + publish
│   ├── copy-resource-bundle.sh     (221 lines) - Resource bundle management
│   ├── inject-resource-accessor.sh (235 lines) - Custom accessor injection
│   ├── publish_to_artifactory.sh   (118 lines) - Artifactory publishing
│   └── setup.sh                    (80 lines)  - Dependency installation
│
├── Documentation
│   ├── README.md                   - Project overview
│   ├── IMPLEMENTATION_PLAN.md      - Ruby migration plan (1,219 lines)
│   ├── CONFIGURATION.md            - Configuration guide
│   ├── MIGRATION_GUIDE.md          - Migration instructions
│   ├── PROJECT_STRUCTURE.md        - Planned Ruby structure
│   └── INDEX.md                    - Documentation index
│
└── Templates
    └── resource_bundle_accessor.swift - Custom Swift resource accessor
```

### 1.2 Key Features (Already Implemented in Bash)

✅ **Framework-Agnostic Design** (Recently refactored - December 2025)
- Environment variable-based configuration
- No hardcoded project names
- Supports any iOS XCFramework project

✅ **Build Capabilities**
- iOS Device (arm64)
- iOS Simulator (arm64)
- Conditional builds (device-only, simulator-only, or both)
- Library evolution for ABI stability
- Debug symbols (dSYM) generation

✅ **Resource Management**
- SPM resource bundle copying
- Custom resource accessor injection
- Recompilation of modified Swift files

✅ **Publishing & Distribution**
- Artifactory/JFrog publishing
- Git tagging and versioning
- Slack notifications (optional)
- SHA256 checksum generation

✅ **Developer Experience**
- Build output formatting (xcbeautify/xcpretty)
- Colored terminal output
- Progress indicators
- Incremental builds (--no-clean)
- Verbose mode for debugging

### 1.3 Current Configuration System

**Environment Variables** (Primary method):
```bash
XCODE_PROJECT_NAME      # Project name (without .xcodeproj)
FRAMEWORK_NAMES         # Space-separated framework names
SDK_OUTPUT_DIR_NAME     # Output directory name
RESOURCE_MODULE_NAME    # Module for resource bundle injection
```

**Publishing Variables**:
```bash
VERSION                 # Semantic version
ARTIFACTORY_URL         # JFrog/Artifactory URL
ARTIFACTORY_USERNAME    # Username
JFROG_ACCESS_TOKEN      # Access token
PACKAGE_SCOPE           # Package scope (e.g., "com.company")
GIT_BRANCH              # Git branch (default: master)
SLACK_WEBHOOK_URL       # Optional Slack webhook
```

### 1.4 Identified Limitations & Pain Points

**Bash Script Limitations**:
1. ❌ No type safety or validation
2. ❌ Limited error handling and recovery
3. ❌ Difficult to test (no unit tests)
4. ❌ Hard to extend with new platforms
5. ❌ String-based configuration prone to errors
6. ❌ No interactive configuration wizard
7. ❌ Limited cross-platform support
8. ❌ No plugin/extension system

**Hardcoded Assumptions**:
1. 🔸 Only supports iOS (device + simulator)
2. 🔸 Only arm64 architecture (excludes x86_64)
3. 🔸 Fixed deployment target (iOS 16.0)
4. 🔸 Single resource bundle name hardcoded in template
5. 🔸 No support for macOS, tvOS, watchOS, visionOS, Catalyst

**Configuration Challenges**:
1. 🔸 No schema validation
2. 🔸 Environment variables scattered across scripts
3. 🔸 No default configuration file
4. 🔸 Manual setup required for each project

---

## 📋 PART 2: REFACTORING GOALS & REQUIREMENTS

### 2.1 Primary Objectives

1. **Maintain Feature Parity**: All existing Bash functionality must work in Ruby
2. **Enhance Generalization**: Support all Apple platforms (iOS, macOS, tvOS, watchOS, visionOS, Catalyst)
3. **Improve Architecture**: Support multiple architectures (arm64, x86_64, arm64-simulator)
4. **Better Configuration**: YAML/JSON config with validation and schema
5. **Enhanced Testing**: 90%+ code coverage with RSpec
6. **Professional UX**: Interactive prompts, better error messages, progress indicators
7. **Extensibility**: Plugin system for custom build steps
8. **Documentation**: Comprehensive API docs and examples

### 2.2 Non-Functional Requirements

- **Ruby Version**: 3.0+ (modern Ruby features)
- **macOS Compatibility**: macOS 12.0+ (Monterey or later)
- **Xcode Version**: 14.0+ (supports all platforms)
- **Performance**: Build times should match or improve upon Bash scripts
- **Backward Compatibility**: Support existing environment variable configuration
- **Error Recovery**: Graceful handling of build failures with cleanup

### 2.3 Success Criteria

✅ Can build XCFrameworks for any Apple platform
✅ Configuration via YAML, JSON, or Ruby DSL
✅ 90%+ test coverage
✅ Interactive setup wizard for new projects
✅ Comprehensive error messages with suggestions
✅ Plugin system for custom build steps
✅ Published as a Ruby gem
✅ Complete documentation with examples

---

## 🔍 PART 3: DETAILED COMPONENT ANALYSIS

### 3.1 Build System Analysis

**Current Implementation** (`create-xcframework.sh`):

**Strengths**:
- ✅ Sequential build process (reliable)
- ✅ Proper archive creation with xcodebuild
- ✅ Debug symbols (dSYM) inclusion
- ✅ Library evolution enabled
- ✅ Private interface cleanup

**Limitations**:
- ❌ Hardcoded iOS-only destinations
- ❌ Fixed arm64 architecture
- ❌ No parallel build support
- ❌ Limited platform abstraction

**Key Build Steps**:
1. Clean previous builds (optional with --no-clean)
2. Clean Xcode build state
3. Build iOS Device archive (arm64)
4. Build iOS Simulator archive (arm64)
5. Copy resource bundles into frameworks
6. Inject custom resource accessors
7. Create XCFramework from archives
8. Generate checksum (optional)
9. Cleanup build artifacts

**xcodebuild Command Pattern**:
```bash
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -archivePath "$ARCHIVE_PATH" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ARCHS="arm64" \
    ONLY_ACTIVE_ARCH=NO \
    EXCLUDED_ARCHS="x86_64" \
    OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"
```

### 3.2 Platform & Architecture Matrix

**Current Support**:
| Platform | Architectures | Destination |
|----------|---------------|-------------|
| iOS Device | arm64 | `generic/platform=iOS` |
| iOS Simulator | arm64 | `generic/platform=iOS Simulator` |

**Target Support** (Ruby implementation):
| Platform | Architectures | Destination | SDK |
|----------|---------------|-------------|-----|
| iOS Device | arm64 | `generic/platform=iOS` | iphoneos |
| iOS Simulator | arm64, x86_64 | `generic/platform=iOS Simulator` | iphonesimulator |
| macOS | arm64, x86_64 | `generic/platform=macOS` | macosx |
| macOS Catalyst | arm64, x86_64 | `generic/platform=macOS,variant=Mac Catalyst` | macosx |
| tvOS Device | arm64 | `generic/platform=tvOS` | appletvos |
| tvOS Simulator | arm64, x86_64 | `generic/platform=tvOS Simulator` | appletvsimulator |
| watchOS Device | arm64_32, arm64 | `generic/platform=watchOS` | watchos |
| watchOS Simulator | arm64, x86_64 | `generic/platform=watchOS Simulator` | watchsimulator |
| visionOS Device | arm64 | `generic/platform=visionOS` | xros |
| visionOS Simulator | arm64 | `generic/platform=visionOS Simulator` | xrsimulator |

### 3.3 Resource Management Analysis

**Current Implementation**:

**copy-resource-bundle.sh**:
- Searches for bundles in `UninstalledProducts/{platform_sdk}/`
- Copies bundles into framework directory
- Supports configurable bundle names
- Platform-aware (iphoneos vs iphonesimulator)

**inject-resource-accessor.sh**:
- Finds SPM's auto-generated `resource_bundle_accessor.swift`
- Replaces with custom template (extended search paths)
- Recompiles `.o` file with swiftc
- Module-specific injection

**Challenges**:
1. Resource bundle names vary by SPM package
2. Search paths differ between platforms
3. Recompilation requires correct SDK and target triple
4. Template has hardcoded bundle name references

**Ruby Enhancement Opportunities**:
- Dynamic template generation with variable substitution
- Multi-bundle support with configuration
- Platform-aware SDK path resolution
- Better error messages when bundles not found

### 3.4 Configuration Management Analysis

**Current System** (Bash):
```bash
# config.sh - Environment variable based
XCODE_PROJECT_NAME="${XCODE_PROJECT_NAME:-MyProject}"
FRAMEWORK_NAMES="${FRAMEWORK_NAMES:-}"
SDK_OUTPUT_DIR_NAME="${SDK_OUTPUT_DIR_NAME:-SDKOutput}"
RESOURCE_MODULE_NAME="${RESOURCE_MODULE_NAME:-}"
```

**Proposed Ruby System** (YAML):
```yaml
# .xcframework.yml
project:
  name: "MyProject"
  workspace_root: "../../.."
  xcode_project: "MyProject.xcodeproj"

frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms:
      - ios
      - ios-simulator
      - macos
    architectures:
      ios: [arm64]
      ios-simulator: [arm64, x86_64]
      macos: [arm64, x86_64]
    resource_bundles:
      - "my_theme_ui_my_theme_ui.bundle"
    resource_module: "my_theme_ui"

build:
  output_dir: "build"
  derived_data: "build/DerivedData"
  log_dir: "build/logs"
  xcframework_output: "../../SDKOutput"

publishing:
  artifactory_url: "${ARTIFACTORY_URL}"
  package_scope: "com.mycompany"
  git_branch: "master"
  slack_webhook: "${SLACK_WEBHOOK_URL}"
```

---

## 🏗️ PART 4: RUBY ARCHITECTURE DESIGN

### 4.1 Module Structure

```
lib/xcframework_cli/
├── version.rb              # Version constant
├── cli.rb                  # Thor CLI interface
├── config/
│   ├── loader.rb           # Config file loading (YAML/JSON)
│   ├── validator.rb        # Schema validation
│   ├── schema.rb           # Configuration schema definition
│   └── defaults.rb         # Default values
├── platform/
│   ├── base.rb             # Base platform class
│   ├── ios.rb              # iOS platform
│   ├── macos.rb            # macOS platform
│   ├── tvos.rb             # tvOS platform
│   ├── watchos.rb          # watchOS platform
│   ├── visionos.rb         # visionOS platform
│   ├── catalyst.rb         # Mac Catalyst
│   └── registry.rb         # Platform registry
├── builder/
│   ├── orchestrator.rb     # Build orchestration
│   ├── archiver.rb         # Archive creation
│   ├── xcframework.rb      # XCFramework assembly
│   └── cleaner.rb          # Cleanup operations
├── resource/
│   ├── manager.rb          # Resource bundle management
│   ├── accessor_injector.rb # Swift accessor injection
│   └── template_engine.rb  # Template rendering
├── xcodebuild/
│   ├── wrapper.rb          # xcodebuild command wrapper
│   ├── formatter.rb        # Output formatting
│   └── error_parser.rb     # Error parsing
├── publisher/
│   ├── artifactory.rb      # Artifactory publishing
│   ├── git_tagger.rb       # Git tagging
│   └── notifier.rb         # Slack/webhook notifications
├── utils/
│   ├── logger.rb           # Colored logging
│   ├── spinner.rb          # Progress indicators
│   ├── file_utils.rb       # File operations
│   └── checksum.rb         # SHA256 generation
└── errors.rb               # Custom error classes
```

### 4.2 Core Classes Design

#### 4.2.1 Platform Abstraction

```ruby
# lib/xcframework_cli/platform/base.rb
module XCFrameworkCLI
  module Platform
    class Base
      attr_reader :name, :sdk, :destination, :supported_archs

      def initialize
        @name = self.class.platform_name
        @sdk = self.class.sdk_name
        @destination = self.class.destination_string
        @supported_archs = self.class.architectures
      end

      def self.platform_name
        raise NotImplementedError
      end

      def self.sdk_name
        raise NotImplementedError
      end

      def self.destination_string
        raise NotImplementedError
      end

      def self.architectures
        raise NotImplementedError
      end

      def sdk_path
        `xcrun --sdk #{sdk} --show-sdk-path`.strip
      end

      def target_triple(arch, deployment_target)
        "#{arch}-apple-#{target_os}#{deployment_target}"
      end

      def target_os
        raise NotImplementedError
      end
    end
  end
end

# lib/xcframework_cli/platform/ios.rb
module XCFrameworkCLI
  module Platform
    class IOS < Base
      def self.platform_name
        'iOS'
      end

      def self.sdk_name
        'iphoneos'
      end

      def self.destination_string
        'generic/platform=iOS'
      end

      def self.architectures
        ['arm64']
      end

      def target_os
        'ios'
      end
    end

    class IOSSimulator < Base
      def self.platform_name
        'iOS Simulator'
      end

      def self.sdk_name
        'iphonesimulator'
      end

      def self.destination_string
        'generic/platform=iOS Simulator'
      end

      def self.architectures
        ['arm64', 'x86_64']
      end

      def target_os
        'ios-simulator'
      end
    end
  end
end
```

#### 4.2.2 Configuration Management

```ruby
# lib/xcframework_cli/config/loader.rb
module XCFrameworkCLI
  module Config
    class Loader
      def self.load(path = nil)
        config_path = find_config_file(path)
        raw_config = parse_config_file(config_path)
        validated_config = Validator.validate(raw_config)
        merge_with_defaults(validated_config)
      end

      private

      def self.find_config_file(path)
        return path if path && File.exist?(path)

        candidates = [
          '.xcframework.yml',
          '.xcframework.yaml',
          'xcframework.yml',
          'config/xcframework.yml'
        ]

        candidates.find { |f| File.exist?(f) } || raise ConfigError, "No config file found"
      end

      def self.parse_config_file(path)
        case File.extname(path)
        when '.yml', '.yaml'
          YAML.load_file(path, symbolize_names: true)
        when '.json'
          JSON.parse(File.read(path), symbolize_names: true)
        else
          raise ConfigError, "Unsupported config format: #{path}"
        end
      end
    end
  end
end
```

#### 4.2.3 Build Orchestrator

```ruby
# lib/xcframework_cli/builder/orchestrator.rb
module XCFrameworkCLI
  module Builder
    class Orchestrator
      attr_reader :config, :logger

      def initialize(config, logger: Logger.new)
        @config = config
        @logger = logger
      end

      def build(framework_name, platforms: :all, clean: true)
        framework_config = find_framework_config(framework_name)
        platforms_to_build = resolve_platforms(framework_config, platforms)

        logger.header("Building #{framework_name} XCFramework")

        Cleaner.clean(config) if clean

        archives = platforms_to_build.map do |platform|
          build_archive(framework_config, platform)
        end

        xcframework_path = XCFramework.create(
          framework_name: framework_name,
          archives: archives,
          output_dir: config.xcframework_output
        )

        logger.success("XCFramework created: #{xcframework_path}")
        xcframework_path
      end

      private

      def build_archive(framework_config, platform)
        logger.step("Building for #{platform.name}")

        archiver = Archiver.new(
          project: config.xcode_project,
          scheme: framework_config.scheme,
          platform: platform,
          config: config
        )

        archive_path = archiver.build

        # Post-build steps
        ResourceManager.copy_bundles(archive_path, framework_config, platform)
        AccessorInjector.inject(archive_path, framework_config, platform)

        archive_path
      end
    end
  end
end
```

### 4.3 Configuration Schema

```ruby
# lib/xcframework_cli/config/schema.rb
module XCFrameworkCLI
  module Config
    class Schema
      SCHEMA = {
        project: {
          required: true,
          type: Hash,
          schema: {
            name: { required: true, type: String },
            workspace_root: { required: false, type: String },
            xcode_project: { required: true, type: String }
          }
        },
        frameworks: {
          required: true,
          type: Array,
          items: {
            type: Hash,
            schema: {
              name: { required: true, type: String },
              scheme: { required: true, type: String },
              bundle_id: { required: false, type: String },
              platforms: {
                required: true,
                type: Array,
                items: { type: String, enum: SUPPORTED_PLATFORMS }
              },
              architectures: {
                required: false,
                type: Hash
              },
              resource_bundles: {
                required: false,
                type: Array,
                items: { type: String }
              },
              resource_module: {
                required: false,
                type: String
              },
              deployment_targets: {
                required: false,
                type: Hash
              }
            }
          }
        },
        build: {
          required: false,
          type: Hash,
          schema: {
            output_dir: { required: false, type: String, default: 'build' },
            derived_data: { required: false, type: String },
            log_dir: { required: false, type: String },
            xcframework_output: { required: false, type: String }
          }
        },
        publishing: {
          required: false,
          type: Hash
        }
      }

      SUPPORTED_PLATFORMS = %w[
        ios ios-simulator
        macos catalyst
        tvos tvos-simulator
        watchos watchos-simulator
        visionos visionos-simulator
      ].freeze
    end
  end
end
```

---

## 📝 PART 5: IMPLEMENTATION PLAN

### 5.1 Phase 1: Foundation (Week 1)

**Goal**: Set up project structure and core infrastructure

**Tasks**:
1. ✅ Create Ruby project structure
   - Initialize gem with `bundle gem xcframework-cli`
   - Set up directory structure
   - Configure RuboCop and RSpec

2. ✅ Implement configuration system
   - `Config::Loader` - YAML/JSON parsing
   - `Config::Validator` - Schema validation
   - `Config::Schema` - Schema definition
   - `Config::Defaults` - Default values

3. ✅ Implement logging and UI
   - `Utils::Logger` - Colored output
   - `Utils::Spinner` - Progress indicators
   - Error classes hierarchy

4. ✅ Write tests
   - Config loading tests
   - Validation tests
   - Logger tests

**Deliverables**:
- Working config system with validation
- Comprehensive test suite (90%+ coverage)
- Basic CLI skeleton

### 5.2 Phase 2: Platform Abstraction (Week 2)

**Goal**: Implement platform-specific logic

**Tasks**:
1. ✅ Create platform base class
   - `Platform::Base` - Abstract platform
   - Platform registry pattern

2. ✅ Implement platform classes
   - `Platform::IOS` and `Platform::IOSSimulator`
   - `Platform::MacOS` and `Platform::Catalyst`
   - `Platform::TVOS` and `Platform::TVOSSimulator`
   - `Platform::WatchOS` and `Platform::WatchOSSimulator`
   - `Platform::VisionOS` and `Platform::VisionOSSimulator`

3. ✅ Platform utilities
   - SDK path resolution
   - Target triple generation
   - Architecture validation

4. ✅ Write tests
   - Platform instantiation
   - SDK path resolution
   - Target triple generation

**Deliverables**:
- Complete platform abstraction
- Support for all Apple platforms
- Platform-specific tests

### 5.3 Phase 3: Build System (Week 3)

**Goal**: Implement core build functionality

**Tasks**:
1. ✅ xcodebuild wrapper
   - `Xcodebuild::Wrapper` - Command execution
   - `Xcodebuild::Formatter` - Output formatting
   - `Xcodebuild::ErrorParser` - Error parsing

2. ✅ Build orchestration
   - `Builder::Orchestrator` - Main build logic
   - `Builder::Archiver` - Archive creation
   - `Builder::XCFramework` - XCFramework assembly
   - `Builder::Cleaner` - Cleanup operations

3. ✅ Integration with platforms
   - Platform-specific build parameters
   - Architecture handling
   - Multi-platform builds

4. ✅ Write tests
   - Mock xcodebuild execution
   - Build orchestration tests
   - Error handling tests

**Deliverables**:
- Working build system
- Support for all platforms
- Comprehensive error handling

### 5.4 Phase 4: Resource Management (Week 4)

**Goal**: Implement resource bundle handling

**Tasks**:
1. ✅ Resource bundle manager
   - `Resource::Manager` - Bundle discovery and copying
   - Platform-aware bundle search
   - Multi-bundle support

2. ✅ Accessor injection
   - `Resource::AccessorInjector` - Swift file injection
   - `Resource::TemplateEngine` - Template rendering
   - Dynamic template generation

3. ✅ Template system
   - ERB-based templates
   - Variable substitution
   - Platform-specific templates

4. ✅ Write tests
   - Bundle discovery tests
   - Injection tests
   - Template rendering tests

**Deliverables**:
- Resource bundle management
- Custom accessor injection
- Template system

### 5.5 Phase 5: Publishing & Polish (Week 5)

**Goal**: Publishing, documentation, and final polish

**Tasks**:
1. ✅ Publishing system
   - `Publisher::Artifactory` - JFrog publishing
   - `Publisher::GitTagger` - Git tagging
   - `Publisher::Notifier` - Slack notifications

2. ✅ CLI commands
   - `build` - Build XCFrameworks
   - `clean` - Clean artifacts
   - `publish` - Publish to Artifactory
   - `init` - Interactive setup wizard
   - `validate` - Validate configuration

3. ✅ Documentation
   - API documentation (YARD)
   - User guide
   - Examples and tutorials
   - Migration guide from Bash

4. ✅ Gem packaging
   - Gemspec configuration
   - Executable setup
   - Release preparation

**Deliverables**:
- Complete CLI tool
- Published gem
- Comprehensive documentation

---

## 🔧 PART 6: DETAILED FILE CHANGES

### 6.1 New Ruby Files to Create

**Core Library** (lib/xcframework_cli/):
```
✅ version.rb                           # Version constant
✅ cli.rb                               # Thor CLI interface
✅ errors.rb                            # Custom error classes

✅ config/loader.rb                     # Config file loading
✅ config/validator.rb                  # Schema validation
✅ config/schema.rb                     # Configuration schema
✅ config/defaults.rb                   # Default values

✅ platform/base.rb                     # Base platform class
✅ platform/ios.rb                      # iOS + iOS Simulator
✅ platform/macos.rb                    # macOS + Catalyst
✅ platform/tvos.rb                     # tvOS + tvOS Simulator
✅ platform/watchos.rb                  # watchOS + watchOS Simulator
✅ platform/visionos.rb                 # visionOS + visionOS Simulator
✅ platform/registry.rb                 # Platform registry

✅ builder/orchestrator.rb              # Build orchestration
✅ builder/archiver.rb                  # Archive creation
✅ builder/xcframework.rb               # XCFramework assembly
✅ builder/cleaner.rb                   # Cleanup operations

✅ resource/manager.rb                  # Resource bundle management
✅ resource/accessor_injector.rb        # Swift accessor injection
✅ resource/template_engine.rb          # Template rendering

✅ xcodebuild/wrapper.rb                # xcodebuild wrapper
✅ xcodebuild/formatter.rb              # Output formatting
✅ xcodebuild/error_parser.rb           # Error parsing

✅ publisher/artifactory.rb             # Artifactory publishing
✅ publisher/git_tagger.rb              # Git tagging
✅ publisher/notifier.rb                # Notifications

✅ utils/logger.rb                      # Colored logging
✅ utils/spinner.rb                     # Progress indicators
✅ utils/file_utils.rb                  # File operations
✅ utils/checksum.rb                    # SHA256 generation
```

**Executable** (bin/):
```
✅ xcframework-cli                      # Main executable
```

**Tests** (spec/):
```
✅ spec_helper.rb                       # RSpec configuration

✅ unit/config_spec.rb                  # Config tests
✅ unit/platform_spec.rb                # Platform tests
✅ unit/builder_spec.rb                 # Builder tests
✅ unit/resource_spec.rb                # Resource tests
✅ unit/xcodebuild_spec.rb              # Xcodebuild tests
✅ unit/publisher_spec.rb               # Publisher tests
✅ unit/utils_spec.rb                   # Utils tests

✅ integration/build_spec.rb            # End-to-end build tests
✅ integration/publish_spec.rb          # Publishing tests
```

**Configuration** (config/):
```
✅ default.yml                          # Default configuration
✅ examples/ios_framework.yml           # iOS example
✅ examples/multiplatform.yml           # Multi-platform example
```

**Templates** (templates/):
```
✅ resource_bundle_accessor.swift.erb   # ERB template (from existing)
✅ xcframework.yml.erb                  # Config template for init
```

**Documentation**:
```
✅ README.md                            # Update with Ruby usage
✅ ARCHITECTURE.md                      # Architecture documentation
✅ API.md                               # API reference
✅ EXAMPLES.md                          # Usage examples
✅ MIGRATION_FROM_BASH.md               # Migration guide
```

**Gem Files**:
```
✅ Gemfile                              # Dependencies
✅ Gemfile.lock                         # Locked dependencies
✅ xcframework-cli.gemspec              # Gem specification
✅ Rakefile                             # Rake tasks
✅ .rubocop.yml                         # RuboCop configuration
✅ .rspec                               # RSpec configuration
```

### 6.2 Bash Scripts to Modify/Deprecate

**Keep for Reference** (move to `legacy/`):
```
→ legacy/config.sh                      # Reference for env vars
→ legacy/create-xcframework.sh          # Reference for build logic
→ legacy/debug.sh                       # Reference for CLI
→ legacy/release.sh                     # Reference for workflow
→ legacy/copy-resource-bundle.sh        # Reference for resources
→ legacy/inject-resource-accessor.sh    # Reference for injection
→ legacy/publish_to_artifactory.sh      # Reference for publishing
→ legacy/setup.sh                       # Reference for setup
```

**Update**:
```
✏️ README.md                            # Update with Ruby instructions
✏️ CONFIGURATION.md                     # Update for YAML config
```

### 6.3 Configuration File Examples

**Example 1: Simple iOS Framework** (config/examples/ios_framework.yml):
```yaml
project:
  name: "MyApp"
  xcode_project: "MyApp.xcodeproj"

frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms:
      - ios
      - ios-simulator

build:
  output_dir: "build"
  xcframework_output: "../SDKs"
```

**Example 2: Multi-Platform Framework** (config/examples/multiplatform.yml):
```yaml
project:
  name: "UniversalSDK"
  xcode_project: "UniversalSDK.xcodeproj"

frameworks:
  - name: "CoreSDK"
    scheme: "CoreSDK"
    platforms:
      - ios
      - ios-simulator
      - macos
      - catalyst
      - tvos
      - tvos-simulator
    architectures:
      ios: [arm64]
      ios-simulator: [arm64, x86_64]
      macos: [arm64, x86_64]
      catalyst: [arm64, x86_64]
      tvos: [arm64]
      tvos-simulator: [arm64, x86_64]
    deployment_targets:
      ios: "14.0"
      macos: "11.0"
      tvos: "14.0"

build:
  output_dir: "build"
  xcframework_output: "../Frameworks"
  parallel_builds: true
```

**Example 3: Framework with Resources** (config/examples/resources.yml):
```yaml
project:
  name: "ThemeSDK"
  xcode_project: "ThemeSDK.xcodeproj"

frameworks:
  - name: "ThemeSDK"
    scheme: "ThemeSDK"
    platforms:
      - ios
      - ios-simulator
    resource_bundles:
      - "theme_ui_theme_ui.bundle"
      - "assets_assets.bundle"
    resource_module: "theme_ui"
    resource_accessor_template: "templates/custom_accessor.swift.erb"

build:
  output_dir: "build"
  xcframework_output: "../SDKs"
```

---

## 🎯 PART 7: IMPLEMENTATION STEPS

### 7.1 Step-by-Step Implementation Guide

#### Step 1: Project Initialization
```bash
# Create gem structure
bundle gem xcframework-cli --test=rspec --ci=github --linter=rubocop

# Navigate to project
cd xcframework-cli

# Install dependencies
bundle install
```

#### Step 2: Set Up Directory Structure
```bash
# Create directory structure
mkdir -p lib/xcframework_cli/{config,platform,builder,resource,xcodebuild,publisher,utils}
mkdir -p spec/{unit,integration}
mkdir -p config/examples
mkdir -p templates
mkdir -p legacy

# Move existing Bash scripts to legacy
mv *.sh legacy/
```

#### Step 3: Implement Core Classes (Priority Order)

**Priority 1: Foundation**
1. `lib/xcframework_cli/errors.rb` - Error classes
2. `lib/xcframework_cli/utils/logger.rb` - Logging
3. `lib/xcframework_cli/config/schema.rb` - Schema definition
4. `lib/xcframework_cli/config/validator.rb` - Validation
5. `lib/xcframework_cli/config/loader.rb` - Config loading
6. `lib/xcframework_cli/config/defaults.rb` - Defaults

**Priority 2: Platform Abstraction**
7. `lib/xcframework_cli/platform/base.rb` - Base platform
8. `lib/xcframework_cli/platform/ios.rb` - iOS platforms
9. `lib/xcframework_cli/platform/macos.rb` - macOS platforms
10. `lib/xcframework_cli/platform/registry.rb` - Platform registry

**Priority 3: Build System**
11. `lib/xcframework_cli/xcodebuild/wrapper.rb` - xcodebuild wrapper
12. `lib/xcframework_cli/xcodebuild/formatter.rb` - Output formatting
13. `lib/xcframework_cli/builder/cleaner.rb` - Cleanup
14. `lib/xcframework_cli/builder/archiver.rb` - Archive creation
15. `lib/xcframework_cli/builder/xcframework.rb` - XCFramework assembly
16. `lib/xcframework_cli/builder/orchestrator.rb` - Orchestration

**Priority 4: Resource Management**
17. `lib/xcframework_cli/resource/template_engine.rb` - Templates
18. `lib/xcframework_cli/resource/manager.rb` - Bundle management
19. `lib/xcframework_cli/resource/accessor_injector.rb` - Injection

**Priority 5: Publishing**
20. `lib/xcframework_cli/publisher/git_tagger.rb` - Git tagging
21. `lib/xcframework_cli/publisher/notifier.rb` - Notifications
22. `lib/xcframework_cli/publisher/artifactory.rb` - Publishing

**Priority 6: CLI**
23. `lib/xcframework_cli/cli.rb` - Thor CLI
24. `bin/xcframework-cli` - Executable

#### Step 4: Write Tests (Parallel with Implementation)
```bash
# Run tests continuously during development
bundle exec guard

# Or manually
bundle exec rspec

# Check coverage
bundle exec rspec --format documentation
open coverage/index.html
```

#### Step 5: Create Configuration Examples
```bash
# Create example configs
cat > config/examples/ios_framework.yml << 'EOF'
# [Content from 6.3 above]
EOF

cat > config/examples/multiplatform.yml << 'EOF'
# [Content from 6.3 above]
EOF
```

#### Step 6: Update Templates
```bash
# Convert existing Swift template to ERB
cp templates/resource_bundle_accessor.swift \
   templates/resource_bundle_accessor.swift.erb

# Add ERB variables for dynamic generation
# Replace hardcoded values with <%= bundle_name %>, etc.
```

#### Step 7: Documentation
```bash
# Generate API docs
bundle exec yard doc

# Open docs
open doc/index.html
```

#### Step 8: Testing & Validation
```bash
# Run full test suite
bundle exec rspec

# Run RuboCop
bundle exec rubocop

# Check coverage
bundle exec rspec --format documentation

# Integration test
bundle exec bin/xcframework-cli build MySDK --platforms ios,ios-simulator
```

#### Step 9: Gem Packaging
```bash
# Build gem
gem build xcframework-cli.gemspec

# Install locally
gem install xcframework-cli-0.1.0.gem

# Test installed gem
xcframework-cli --version
xcframework-cli --help
```

#### Step 10: Publishing
```bash
# Publish to RubyGems (when ready)
gem push xcframework-cli-0.1.0.gem
```

---

## 📊 PART 8: CONFIGURATION MANAGEMENT APPROACH

### 8.1 Configuration Hierarchy

**Priority Order** (highest to lowest):
1. Command-line arguments (`--config`, `--platform`, etc.)
2. Environment variables (`XCFRAMEWORK_*`)
3. Project config file (`.xcframework.yml`)
4. User config file (`~/.xcframework.yml`)
5. Default values (hardcoded)

### 8.2 Environment Variable Support

**Backward Compatibility** with existing Bash scripts:
```ruby
# lib/xcframework_cli/config/env_loader.rb
module XCFrameworkCLI
  module Config
    class EnvLoader
      ENV_MAPPINGS = {
        'XCODE_PROJECT_NAME' => 'project.name',
        'FRAMEWORK_NAMES' => 'frameworks[].name',
        'SDK_OUTPUT_DIR_NAME' => 'build.xcframework_output',
        'RESOURCE_MODULE_NAME' => 'frameworks[].resource_module',
        'ARTIFACTORY_URL' => 'publishing.artifactory_url',
        'PACKAGE_SCOPE' => 'publishing.package_scope',
        'VERSION' => 'publishing.version',
        'GIT_BRANCH' => 'publishing.git_branch'
      }.freeze

      def self.load
        config = {}
        ENV_MAPPINGS.each do |env_var, config_path|
          value = ENV[env_var]
          next unless value

          set_nested_value(config, config_path, value)
        end
        config
      end
    end
  end
end
```

### 8.3 Configuration Validation

**Validation Rules**:
- Required fields must be present
- Platform names must be valid
- Architecture combinations must be valid for platform
- File paths must exist (for project files)
- URLs must be valid (for Artifactory)
- Versions must follow semantic versioning

**Example Validation**:
```ruby
# lib/xcframework_cli/config/validator.rb
module XCFrameworkCLI
  module Config
    class Validator
      def self.validate(config)
        errors = []

        # Validate project
        errors << "project.name is required" unless config.dig(:project, :name)
        errors << "project.xcode_project is required" unless config.dig(:project, :xcode_project)

        # Validate frameworks
        frameworks = config[:frameworks]
        errors << "At least one framework is required" if frameworks.nil? || frameworks.empty?

        frameworks&.each_with_index do |fw, idx|
          errors << "frameworks[#{idx}].name is required" unless fw[:name]
          errors << "frameworks[#{idx}].scheme is required" unless fw[:scheme]
          errors << "frameworks[#{idx}].platforms is required" unless fw[:platforms]

          # Validate platforms
          fw[:platforms]&.each do |platform|
            unless Platform::Registry.valid?(platform)
              errors << "Invalid platform: #{platform}"
            end
          end
        end

        raise ConfigError, errors.join("\n") unless errors.empty?

        config
      end
    end
  end
end
```

---

## 🚀 PART 9: CLI COMMAND DESIGN

### 9.1 Command Structure

```bash
xcframework-cli [COMMAND] [OPTIONS]

Commands:
  build       Build XCFrameworks
  clean       Clean build artifacts
  publish     Publish to Artifactory
  init        Initialize configuration
  validate    Validate configuration
  platforms   List supported platforms
  version     Show version
  help        Show help

Global Options:
  --config PATH       Path to config file
  --verbose           Verbose output
  --quiet             Quiet mode
  --no-color          Disable colors
```

### 9.2 Build Command

```bash
xcframework-cli build [FRAMEWORK] [OPTIONS]

Arguments:
  FRAMEWORK           Framework name (optional, builds all if not specified)

Options:
  --platforms LIST    Comma-separated platforms (e.g., ios,macos)
  --architectures     Comma-separated architectures
  --clean             Clean before building (default: true)
  --no-clean          Skip cleaning
  --parallel          Build platforms in parallel
  --checksum          Generate SHA256 checksum
  --output DIR        Custom output directory

Examples:
  xcframework-cli build                           # Build all frameworks
  xcframework-cli build MySDK                     # Build specific framework
  xcframework-cli build MySDK --platforms ios     # Build for iOS only
  xcframework-cli build --no-clean --parallel     # Fast incremental build
```

### 9.3 Init Command (Interactive Setup)

```bash
xcframework-cli init [OPTIONS]

Options:
  --interactive       Interactive mode (default)
  --template NAME     Use template (ios, macos, multiplatform)
  --output PATH       Output path for config file

Interactive Prompts:
  1. Project name?
  2. Xcode project path?
  3. Framework name(s)?
  4. Target platforms? (multi-select)
  5. Resource bundles? (optional)
  6. Output directory?
  7. Publishing setup? (optional)

Example:
  xcframework-cli init
  # Generates .xcframework.yml with user input
```

### 9.4 Publish Command

```bash
xcframework-cli publish [FRAMEWORK] [OPTIONS]

Arguments:
  FRAMEWORK           Framework name (optional, publishes all if not specified)

Options:
  --version VERSION   Version to publish (required)
  --tag               Create git tag (default: true)
  --no-tag            Skip git tagging
  --notify            Send notifications (default: true if configured)
  --dry-run           Show what would be published

Environment Variables:
  ARTIFACTORY_URL
  ARTIFACTORY_USERNAME
  JFROG_ACCESS_TOKEN
  SLACK_WEBHOOK_URL (optional)

Example:
  xcframework-cli publish MySDK --version 1.2.0
```

---

## ⚠️ PART 10: ERROR HANDLING & VALIDATION

### 10.1 Error Classes Hierarchy

```ruby
# lib/xcframework_cli/errors.rb
module XCFrameworkCLI
  class Error < StandardError; end

  class ConfigError < Error; end
  class ValidationError < ConfigError; end
  class FileNotFoundError < ConfigError; end

  class BuildError < Error; end
  class XcodebuildError < BuildError; end
  class ArchiveError < BuildError; end
  class XCFrameworkError < BuildError; end

  class PlatformError < Error; end
  class UnsupportedPlatformError < PlatformError; end
  class InvalidArchitectureError < PlatformError; end

  class ResourceError < Error; end
  class BundleNotFoundError < ResourceError; end
  class InjectionError < ResourceError; end

  class PublishError < Error; end
  class ArtifactoryError < PublishError; end
  class GitError < PublishError; end
end
```

### 10.2 Error Messages with Suggestions

```ruby
# Example error handling
begin
  config = Config::Loader.load
rescue ConfigError => e
  logger.error("Configuration error: #{e.message}")
  logger.info("Suggestions:")
  logger.info("  1. Run 'xcframework-cli init' to create a config file")
  logger.info("  2. Check .xcframework.yml syntax")
  logger.info("  3. See examples: config/examples/")
  exit 1
end
```

### 10.3 Validation Logic

**Pre-build Validation**:
- ✅ Config file exists and is valid
- ✅ Xcode project exists
- ✅ Schemes exist in project
- ✅ Platforms are supported
- ✅ Architectures are valid for platforms
- ✅ Output directories are writable
- ✅ Required tools are installed (xcodebuild, xcrun)

**Post-build Validation**:
- ✅ Archives were created successfully
- ✅ Frameworks exist in archives
- ✅ Debug symbols (dSYM) exist
- ✅ XCFramework structure is valid
- ✅ All platforms are included

---

## 📚 PART 11: TESTING STRATEGY

### 11.1 Unit Tests

**Coverage Target**: 90%+

**Test Structure**:
```ruby
# spec/unit/config/loader_spec.rb
RSpec.describe XCFrameworkCLI::Config::Loader do
  describe '.load' do
    context 'with valid YAML config' do
      it 'loads configuration successfully' do
        # Test implementation
      end
    end

    context 'with invalid config' do
      it 'raises ConfigError' do
        # Test implementation
      end
    end

    context 'with missing file' do
      it 'raises FileNotFoundError' do
        # Test implementation
      end
    end
  end
end
```

### 11.2 Integration Tests

**Test Scenarios**:
1. Build iOS framework (device + simulator)
2. Build multi-platform framework
3. Build with resource bundles
4. Publish to Artifactory (mocked)
5. End-to-end workflow

**Example**:
```ruby
# spec/integration/build_spec.rb
RSpec.describe 'Building XCFrameworks', :integration do
  it 'builds iOS framework successfully' do
    config = create_test_config(platforms: ['ios', 'ios-simulator'])
    orchestrator = XCFrameworkCLI::Builder::Orchestrator.new(config)

    xcframework_path = orchestrator.build('TestSDK')

    expect(File.exist?(xcframework_path)).to be true
    expect(xcframework_valid?(xcframework_path)).to be true
  end
end
```

### 11.3 Mocking Strategy

**Mock xcodebuild**:
```ruby
# spec/support/xcodebuild_mock.rb
module XcodebuildMock
  def mock_xcodebuild_success
    allow(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute)
      .and_return(true)
  end

  def mock_xcodebuild_failure(error_message)
    allow(XCFrameworkCLI::Xcodebuild::Wrapper).to receive(:execute)
      .and_raise(XCFrameworkCLI::XcodebuildError, error_message)
  end
end
```

---

## 🎓 PART 12: MIGRATION PATH FROM BASH

### 12.1 Backward Compatibility

**Support existing environment variables**:
```bash
# Old Bash way (still works)
export XCODE_PROJECT_NAME="MyProject"
export FRAMEWORK_NAMES="MySDK"
xcframework-cli build

# New Ruby way (preferred)
xcframework-cli build --config .xcframework.yml
```

### 12.2 Migration Steps for Users

**Step 1: Install Ruby gem**
```bash
gem install xcframework-cli
```

**Step 2: Generate config from environment**
```bash
# If you have environment variables set
xcframework-cli init --from-env

# Or interactive
xcframework-cli init
```

**Step 3: Test build**
```bash
xcframework-cli build --dry-run
xcframework-cli build
```

**Step 4: Update CI/CD**
```bash
# Old
./debug.sh MySDK --simulator

# New
xcframework-cli build MySDK --platforms ios-simulator
```

### 12.3 Deprecation Timeline

**Phase 1** (Month 1-2): Dual support
- Bash scripts remain in `legacy/`
- Ruby CLI is primary
- Documentation updated

**Phase 2** (Month 3-4): Ruby only
- Bash scripts marked deprecated
- Warning messages added
- Migration guide published

**Phase 3** (Month 5+): Bash removal
- Bash scripts removed
- Ruby CLI only
- Full documentation

---

## 📈 PART 13: SUCCESS METRICS

### 13.1 Technical Metrics

- ✅ 90%+ test coverage
- ✅ All platforms supported (iOS, macOS, tvOS, watchOS, visionOS, Catalyst)
- ✅ Build time ≤ Bash scripts
- ✅ Zero breaking changes for existing users
- ✅ RuboCop score: A+

### 13.2 User Experience Metrics

- ✅ Setup time < 5 minutes (with `init` command)
- ✅ Clear error messages with suggestions
- ✅ Interactive mode for beginners
- ✅ Comprehensive documentation
- ✅ Active community support

### 13.3 Adoption Metrics

- ✅ Published to RubyGems
- ✅ GitHub stars > 50
- ✅ Active users > 10
- ✅ Issues resolved < 7 days
- ✅ Documentation complete

---

## 🎯 PART 14: NEXT IMMEDIATE STEPS

### Priority Actions (Start Now)

1. **Create Task List** ✅
   - Break down implementation into trackable tasks
   - Use task management tools

2. **Set Up Ruby Project** (Day 1)
   ```bash
   bundle gem xcframework-cli --test=rspec
   cd xcframework-cli
   bundle install
   ```

3. **Implement Foundation** (Days 2-3)
   - Error classes
   - Logger
   - Config schema

4. **Create First Working Build** (Days 4-7)
   - Platform abstraction
   - xcodebuild wrapper
   - Simple iOS build

5. **Iterate and Expand** (Weeks 2-5)
   - Add platforms
   - Resource management
   - Publishing
   - Polish

### Questions to Address Before Starting

1. ❓ Should we support Ruby 2.7 or require 3.0+?
   - **Recommendation**: Require Ruby 3.0+ for modern features

2. ❓ Should we use Thor or another CLI framework?
   - **Recommendation**: Thor (proven, well-documented)

3. ❓ YAML, JSON, or Ruby DSL for configuration?
   - **Recommendation**: YAML (primary), JSON (secondary), Ruby DSL (future)

4. ❓ Should we support parallel builds?
   - **Recommendation**: Yes, but optional (--parallel flag)

5. ❓ How to handle breaking changes from Bash?
   - **Recommendation**: Environment variable compatibility layer

---

## 📝 SUMMARY

This refactoring plan provides:

✅ **Comprehensive Analysis** of existing Bash scripts
✅ **Detailed Architecture** for Ruby implementation
✅ **Step-by-Step Implementation Plan** with priorities
✅ **Configuration Management** approach (YAML/JSON)
✅ **Platform Abstraction** for all Apple platforms
✅ **Testing Strategy** with 90%+ coverage goal
✅ **Migration Path** from Bash to Ruby
✅ **CLI Design** with interactive setup
✅ **Error Handling** with helpful suggestions
✅ **Success Metrics** and timeline

**Estimated Timeline**: 5 weeks
**Estimated Effort**: 1 developer, full-time
**Risk Level**: Low (Bash scripts remain as fallback)

**Ready to proceed with implementation!** 🚀


