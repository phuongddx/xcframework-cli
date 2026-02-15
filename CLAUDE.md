# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

XCFramework CLI is a Ruby gem for building XCFrameworks across all Apple platforms (iOS, macOS, tvOS, watchOS, visionOS, Catalyst). The project is transitioning from legacy bash scripts to a modular Ruby architecture. Phase 1 (Foundation) is complete with iOS and iOS Simulator platforms fully implemented.

**Current State**: Phase 1 complete (Dec 6, 2025). Branch: `main`.

## Build & Test Commands

```bash
# Run tests with 80% coverage requirement
bundle exec rake spec

# Run tests without coverage requirement
bundle exec rake test

# Lint code
bundle exec rake rubocop

# Auto-fix linting issues
bundle exec rake lint_fix

# Interactive console (loads gem)
bundle exec rake console

# Run default task (spec + rubocop)
bundle exec rake
```

**Coverage reports**: Generated in `coverage/index.html` after running tests.

## Architecture Overview

### Module Hierarchy

```
XCFrameworkCLI (top-level module)
├── CLI::Runner              # Thor-based command interface
├── CLI::Commands::Build     # Build command implementation
├── Builder::Orchestrator    # Coordinates full build pipeline
├── Builder::Cleaner         # Removes build artifacts
├── Builder::Archiver        # Creates .xcarchive per platform
├── Builder::XCFramework     # Assembles final .xcframework
├── Platform::Registry       # Factory for platform instances
├── Platform::Base           # Abstract class defining platform interface
├── Platform::IOS            # iOS device implementation
├── Platform::IOSSimulator   # iOS Simulator implementation
├── Config::Loader           # YAML/JSON config loader
├── Config::Schema           # Dry-validation schema (10 platforms defined)
├── Config::Defaults         # Default values for all configs
├── Xcodebuild::Wrapper      # Ruby interface to xcodebuild (in progress)
└── Utils::Logger            # Colored output with emoji, verbose/quiet modes
```

### Build Pipeline Flow

1. **Clean** (optional) → 2. **Archive** (per platform) → 3. **Assemble XCFramework**

The `Orchestrator` (`lib/xcframework_cli/builder/orchestrator.rb`) coordinates this pipeline. Each step returns a hash with `:success`, `:error`, and step-specific data (`:xcframework_path`, `:archives`, etc).

### Platform Abstraction Pattern

All platforms inherit from `Platform::Base` (`lib/xcframework_cli/platform/base.rb`) which defines **class methods**:

- `.platform_name` - human-readable name (e.g., "iOS", "iOS Simulator")
- `.platform_identifier` - used in config files (e.g., "ios", "ios-simulator")
- `.sdk_name` - for xcodebuild `-sdk` flag (e.g., "iphoneos", "iphonesimulator")
- `.destination` - for xcodebuild `-destination` (e.g., "generic/platform=iOS")
- `.valid_architectures` - array of supported archs (e.g., ["arm64"])
- `.default_deployment_target` - minimum OS version (e.g., "14.0")

**Instance methods** delegate to class methods. Use `Platform::Base#execute_command(cmd)` for shell execution.

**Currently implemented**: iOS, iOS Simulator. **Schema supports**: All 10 Apple platforms (see `Config::Schema::VALID_PLATFORMS`).

## Configuration Files

Config files are searched in this order:
1. `.xcframework.yml`
2. `.xcframework.yaml`
3. `xcframework.yml`
4. `xcframework.yaml`
5. `.xcframework.json`
6. `xcframework.json`

See `config/examples/basic.yml` and `config/examples/comprehensive.yml` for examples.

**Basic structure**:
```yaml
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"
frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms: [ios, ios-simulator]
build:
  configuration: "Release"  # or "Debug"
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
```

## Custom Build Settings

### Configuration
Set the build configuration (Debug or Release):
```yaml
build:
  configuration: "Release"  # Default: "Release"
```

### Build Settings
Add custom xcodebuild flags via `build.build_settings`:

```yaml
build:
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
    ENABLE_BITCODE: "NO"
```

All build settings are passed directly to xcodebuild as `KEY="VALUE"`.

**Common use cases:**
- **Fix module interface errors**: `OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"`
- **Exclude x86_64 simulator**: `EXCLUDED_ARCHS: "x86_64"`
- **Disable bitcode**: `ENABLE_BITCODE: "NO"`

See `config/examples/swift-interface-workaround.yml` for a complete example.

## Testing Conventions

- Use RSpec with `describe`/`context`/`it` blocks
- Mock external commands (xcodebuild, xcrun) using `allow().to receive()`
- Logger is suppressed in tests via `config.before` hook in `spec_helper.rb`
- Test files mirror structure: `spec/unit/builder/orchestrator_spec.rb` tests `lib/xcframework_cli/builder/orchestrator.rb`
- **80% minimum coverage** enforced by SimpleCov (skip with `ENV['SKIP_COVERAGE'] = 'true'`)

## Critical Patterns

### Error Handling

All custom errors inherit from `XCFrameworkCLI::Error` with optional `suggestions` array:

```ruby
raise ValidationError.new(
  "Invalid platform: #{platform}",
  suggestions: [
    "Use 'ios' or 'ios-simulator'",
    "Run 'xckit platforms' to see all options"
  ]
)
```

Display suggestions via `error.full_message`.

### Command Execution

**Always use** `Platform::Base#execute_command(cmd)` for shell commands. It returns stdout and checks `$CHILD_STATUS.success?`. **Never call** `system()` directly - use the wrapper for consistent error handling.

### Logging Pattern

Use `Utils::Logger` methods: `.info()`, `.error()`, `.warning()`, `.debug()`, `.success()`.

- Configure with `.verbose=` and `.quiet=` flags
- **Never use** `puts`/`print` in production code - always use logger
- Logger output is suppressed in tests (see `spec_helper.rb`)

### xcodebuild Integration

The `Xcodebuild::Wrapper` (`lib/xcframework_cli/xcodebuild/wrapper.rb`) is in progress. Current implementation in `Builder::Archiver` uses direct shell commands. When working with xcodebuild:

- Use `-sdk`, `-destination`, `-archivePath` flags
- Set `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` for library evolution
- Set `SKIP_INSTALL=NO` for proper archive structure
- Return `Xcodebuild::Result` objects with stdout, success flag, and metadata

## Common Development Tasks

### Adding a New Platform

1. Create `lib/xcframework_cli/platform/[platform_name].rb`
2. Inherit from `Platform::Base` and implement all class methods
3. Register in `Platform::Registry::PLATFORMS` hash
4. Add to `Platform::Registry` require statements
5. Create `spec/unit/platform/[platform_name]_spec.rb` with tests

### Adding a New Build Step

1. Create module under `Builder::` (e.g., `Builder::ResourceManager`)
2. Initialize with config hash, implement main action method
3. Return hash with `:success` boolean and relevant data
4. Integrate into `Builder::Orchestrator#build` pipeline
5. Add unit tests mocking external dependencies

### Configuration Schema Changes

1. Update `Config::Schema` validation rules
2. Update `Config::Defaults` with new default values
3. Update example configs in `config/examples/`
4. Add tests in `spec/unit/config/loader_spec.rb`

## Key Reference Documents

- **Architecture**: `docs/ARCHITECTURE_OVERVIEW.md` (visual diagrams, 452 lines)
- **Implementation plan**: `docs/REFACTORING_ANALYSIS_AND_PLAN.md` (1,642 lines, comprehensive roadmap)
- **Task tracking**: `docs/IMPLEMENTATION_CHECKLIST.md` (day-by-day breakdown)
- **Main entry**: `lib/xcframework_cli.rb` (loads all modules)
- **Example project**: `Example/SwiftyBeaver/` (real-world test case)
- **Latest progress**: `docs/PHASE_D_SUMMARY.md` (integration testing summary)
- **Copilot instructions**: `.github/copilot-instructions.md` (comprehensive AI agent guidance)

## Legacy Bash Scripts (Removed)

The legacy bash scripts have been removed from the repository. The Ruby implementation now provides all functionality:
- Resource bundle handling (planned in Phase 4)
- Publishing flow (planned in Phase 5)
- Formatted output via `xcbeautify` or `xcpretty` (✅ implemented)

## What NOT to Do

- Don't add dependencies without discussion (keep gem lightweight)
- Don't modify bash scripts - they're being replaced
- Don't skip tests - 80% coverage is enforced by SimpleCov
- Don't use `puts` - use `Utils::Logger`
- Don't create platform instances directly - use `Platform::Registry.create(identifier)`
- Don't hardcode paths/names - everything should come from config

## Project Status & Next Steps

**Phase 1 (Foundation)**: Complete ✅ - iOS and iOS Simulator platforms working
**Next**: Platform expansion (macOS, tvOS, watchOS, visionOS, Catalyst) and resource management

Check `docs/IMPLEMENTATION_PROGRESS.md` for current status and `docs/IMPLEMENTATION_CHECKLIST.md` for task breakdown.
