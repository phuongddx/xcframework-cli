# XCFramework CLI - Ruby Implementation

A professional Ruby-based CLI tool for building iOS XCFrameworks, replacing the existing Bash scripts with improved maintainability, testability, and user experience.

## 🎉 Current Bash Scripts - Now Framework-Agnostic!

The existing Bash scripts have been **updated to be completely framework-agnostic**. They now work with any iOS XCFramework project, not just ePost-specific ones.

### Quick Start with Bash Scripts

```bash
# Set your project configuration
export XCODE_PROJECT_NAME="MyProject"
export FRAMEWORK_NAMES="MySDK AnotherSDK"

# Build for simulator
./debug.sh --simulator

# Or pass frameworks directly
./debug.sh MySDK AnotherSDK --all
```

📖 **See [CONFIGURATION.md](CONFIGURATION.md) for complete configuration guide**

## 📋 Project Status

**Current Phase**: Planning & Design
**Start Date**: December 4, 2025
**Target Completion**: 5 weeks

## 🎯 Goals

- Replace Bash scripts with maintainable Ruby code
- Improve error handling and user feedback
- Add comprehensive testing (90%+ coverage)
- Maintain 100% feature parity with existing tools
- Enhance developer experience with better CLI UX

## 📚 Documentation

- **[Configuration Guide](CONFIGURATION.md)** - How to configure for your project
- **[Implementation Plan](IMPLEMENTATION_PLAN.md)** - Detailed technical plan and architecture
- **[Original Bash Scripts](../epost-workspace/epost-app/luz_epost_ios/tools/xcframework-cli/)** - Reference implementation

## 🏗️ Planned Architecture

```
xcframework-cli/
├── bin/xcframework-cli          # Executable
├── lib/xcframework_cli/         # Core library
│   ├── cli.rb                   # Thor CLI interface
│   ├── config.rb                # Configuration
│   ├── builder.rb               # Build orchestration
│   ├── platform.rb              # Platform definitions
│   ├── resource_manager.rb      # Resource bundles
│   ├── accessor_injector.rb     # Accessor injection
│   ├── publisher.rb             # Artifactory publishing
│   ├── xcodebuild.rb            # Xcodebuild wrapper
│   └── logger.rb                # Colored logging
├── spec/                        # RSpec tests
├── templates/                   # Swift templates
└── config/                      # Configuration files
```

## 🔧 Technology Stack

- **Ruby 3.0+**
- **Thor** - CLI framework
- **RSpec** - Testing
- **RuboCop** - Linting
- **Colorize** - Terminal colors
- **TTY::Spinner** - Progress indicators

## 📅 Implementation Timeline

| Phase   | Duration | Focus                                         |
| ------- | -------- | --------------------------------------------- |
| Phase 1 | Week 1   | Foundation (Config, Logger, CLI skeleton)     |
| Phase 2 | Week 2   | Core Building (Builder, Xcodebuild, Platform) |
| Phase 3 | Week 3   | Resource Management (Bundles, Accessors)      |
| Phase 4 | Week 4   | Publishing & Polish (Artifactory, Slack)      |
| Phase 5 | Week 5   | Migration & Testing (Validation, Deployment)  |

## 🚀 Quick Start (Future)

Once implemented, the tool will be used like this:

```bash
# Install dependencies
gem install bundler
bundle install

# Build a framework
./bin/xcframework-cli build ePostSDK --simulator

# Debug build (both SDKs)
./bin/xcframework-cli debug --all

# Release build (build + publish)
./bin/xcframework-cli release

# Clean build artifacts
./bin/xcframework-cli clean

# Setup dependencies
./bin/xcframework-cli setup
```

## 📖 Command Reference (Planned)

### Build Command

```bash
xcframework-cli build <FRAMEWORK> [OPTIONS]

Options:
  --all              Build for device + simulator (default)
  --device           Build for device only
  --simulator        Build for simulator only
  --output-dir PATH  Custom output directory
  --no-clean         Skip cleaning build artifacts
  --verbose          Enable verbose output
  --checksum         Generate SHA256 checksum
```

### Debug Command

```bash
xcframework-cli debug [OPTIONS]

Builds both ePostSDK and ePostPushNotificationSDK for testing.
```

### Release Command

```bash
xcframework-cli release

Builds both SDKs and publishes to Artifactory with Git tagging.
```

## 🧪 Testing Strategy

- **Unit Tests**: 90%+ coverage, mock external dependencies
- **Integration Tests**: Full build pipeline validation
- **Acceptance Tests**: Compare with Bash script outputs

## 📊 Success Metrics

- ✅ Feature parity with Bash scripts
- ✅ Build time within 10% of Bash scripts
- ✅ 90%+ test coverage
- ✅ RuboCop score > 95%
- ✅ 100% CI/CD success rate

## 🔗 Related Projects

- **Original Tool**: `luz_epost_ios/tools/xcframework-cli/`
- **Target Frameworks**: ePostSDK, ePostPushNotificationSDK
- **Build System**: Xcode, Swift Package Manager

## 👥 Team

**Project Lead**: Phuong Doan Duy  
**Organization**: AAVN  
**Copyright**: © 2025 AAVN. All rights reserved.

## 📝 Next Steps

1. ✅ Review implementation plan
2. ⏳ Set up project structure
3. ⏳ Implement Phase 1 (Foundation)
4. ⏳ Implement Phase 2 (Core Building)
5. ⏳ Implement Phase 3 (Resource Management)
6. ⏳ Implement Phase 4 (Publishing)
7. ⏳ Implement Phase 5 (Migration)

## 📄 License

Copyright © 2025 AAVN. All rights reserved.

---

**Last Updated**: December 4, 2025  
**Version**: 0.1.0 (Planning)  
**Status**: 🟡 Planning Phase
