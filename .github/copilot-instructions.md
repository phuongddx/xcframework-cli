# XCFramework CLI - AI Agent Instructions

## Project Overview

A professional Ruby gem for building XCFrameworks across all Apple platforms (iOS, macOS, tvOS, watchOS, visionOS, Catalyst). **Current state**: Phase 1 complete (Dec 6, 2025) - Foundation established. Branch: `main`.

The project is transitioning from bash scripts (legacy - DO NOT MODIFY) to a modular Ruby architecture. Currently implemented: iOS and iOS Simulator platforms with full build pipeline.

## Architecture Fundamentals

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

Each step returns hash with `:success`, `:error`, and step-specific data (`:xcframework_path`, `:archives`, etc). The `Orchestrator` (`lib/xcframework_cli/builder/orchestrator.rb`) coordinates this and collects results in a unified hash.

### Platform Abstraction Pattern

All platforms inherit from `Platform::Base` (`lib/xcframework_cli/platform/base.rb`) which defines **class methods**:

- `.platform_name` - human-readable (e.g., "iOS", "iOS Simulator")
- `.platform_identifier` - used in config files (e.g., "ios", "ios-simulator")
- `.sdk_name` - for xcodebuild `-sdk` flag (e.g., "iphoneos", "iphonesimulator")
- `.destination` - for xcodebuild `-destination` (e.g., "generic/platform=iOS")
- `.valid_architectures` - array of supported archs (e.g., ["arm64"])
- `.default_deployment_target` - minimum OS version (e.g., "14.0")

**Instance methods** delegate to class methods. Platforms also implement `#execute_command(cmd)` for shell execution.

**Currently implemented**: iOS (`Platform::IOS`), iOS Simulator (`Platform::IOSSimulator`). **Schema supports**: All 10 Apple platforms (see `Config::Schema::VALID_PLATFORMS`).

## Development Workflows

### Running Tests

```bash
bundle exec rake spec        # Run tests with coverage (80% minimum)
bundle exec rake test        # Run tests without coverage requirement
bundle exec rake rubocop     # Lint code
bundle exec rake lint_fix    # Auto-fix linting issues
```

Coverage reports are in `coverage/index.html`. Always check coverage after adding features.

### Testing Conventions

- Use RSpec with `describe`/`context`/`it` blocks
- Mock external commands (xcodebuild, xcrun) using `allow()` with `receive()`
- Logger is suppressed in tests via `config.before` hook in `spec_helper.rb`
- Test files mirror structure: `spec/unit/builder/orchestrator_spec.rb` tests `lib/xcframework_cli/builder/orchestrator.rb`

### Interactive Console

```bash
bundle exec rake console     # Opens Pry with gem loaded
```

Use this to test classes interactively, e.g., `Platform::Registry.all_platforms`.

### Configuration Files

Look for config in this order: `.xcframework.yml`, `.xcframework.yaml`, `xcframework.yml`, `xcframework.yaml`, `.xcframework.json`, `xcframework.json`. See `config/examples/` for sample configs.

Config structure:

```yaml
project:
  name: "MyProject"
  xcode_project: "MyProject.xcodeproj"
frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms: [ios, ios-simulator]
```

## Critical Patterns

### Error Handling

All custom errors inherit from `XCFrameworkCLI::Error` which supports a `suggestions` array:

```ruby
raise ValidationError.new(
  "Invalid platform: #{platform}",
  suggestions: ["Use 'ios' or 'ios-simulator'", "Run 'xckit platforms' to see all options"]
)
```

Display suggestions via `error.full_message`.

### Command Execution

Use `Platform::Base#execute_command(cmd)` for shell commands. It returns stdout and checks `$CHILD_STATUS.success?`. Never call `system()` directly - use the wrapper for consistent error handling.

### xcodebuild Integration

The `Xcodebuild::Wrapper` (`lib/xcframework_cli/xcodebuild/wrapper.rb`) is in progress. Current implementation in `Builder::Archiver` uses direct shell commands via `Platform::Base#execute_command`. When working with xcodebuild:

- Use `-sdk`, `-destination`, `-archivePath` flags
- Set `BUILD_LIBRARY_FOR_DISTRIBUTION=YES` for library evolution
- Set `SKIP_INSTALL=NO` for proper archive structure
- Return `Xcodebuild::Result` objects with stdout, success flag, and metadata

### Logging Pattern

Use `Utils::Logger` methods: `.info()`, `.error()`, `.warning()`, `.debug()`, `.success()`.

- Logger can be configured with `.verbose=` and `.quiet=` flags
- In production code, use logger instead of `puts`/`print`
- Logger output is suppressed in tests (see `spec_helper.rb`)

## Bash Scripts (Legacy - Being Phased Out)

The project still has bash scripts (`create-xcframework.sh`, `debug.sh`, `release.sh`) that work with environment variables from `config.sh`. These are **reference implementations** - DO NOT modify them. The Ruby code should replicate their logic but with better structure. Key bash insights:

- Resource bundle handling: `copy-resource-bundle.sh` + `inject-resource-accessor.sh`
- Publishing flow: `publish_to_artifactory.sh` uses Swift Package Registry
- Uses `xcbeautify` or `xcpretty` for formatted output

## Common Tasks

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

## Key Files to Reference

- **Architecture**: `ARCHITECTURE_OVERVIEW.md` (visual diagrams, 452 lines)
- **Implementation plan**: `REFACTORING_ANALYSIS_AND_PLAN.md` (1,642 lines, comprehensive roadmap)
- **Task tracking**: `IMPLEMENTATION_CHECKLIST.md` (day-by-day breakdown)
- **Main entry**: `lib/xcframework_cli.rb` (loads all modules)
- **Example project**: `Example/SwiftyBeaver/` (real-world test case)

## What NOT to Do

- Don't add dependencies without discussion (keep gem lightweight)
- Don't modify bash scripts - they're being replaced
- Don't skip tests - 80% coverage is enforced by SimpleCov
- Don't use `puts` - use `Utils::Logger`
- Don't create platform instances directly - use `Platform::Registry.create(identifier)`
- Don't hardcode paths/names - everything should come from config

## Project Status

Phase 1 (Foundation) is complete ✅. Current focus: iOS and iOS Simulator platforms working. Next: Platform expansion (macOS, tvOS, watchOS, visionOS, Catalyst) and resource management. Check `IMPLEMENTATION_PROGRESS.md` for current status.
