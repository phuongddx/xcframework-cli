# XCFramework CLI - Architecture

Simple, modular Ruby CLI for building XCFrameworks from Xcode projects and Swift Packages. This document reflects the current codebase.

---

## 🎯 High-Level Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     XCFramework CLI                              │
│                                                                   │
│  User Input (CLI/Config)                                         │
│         ↓                                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CLI Layer (Thor)                                         │  │
│  │  • bin/xckit                                              │  │
│  │  • Commands: build, spm build, version, help              │  │
│  └──────────────────────────────────────────────────────────┘  │
│         ↓                                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Orchestrator                                             │  │
│  │  • clean (optional) → archive (per platform) → xcframework │ │
│  └──────────────────────────────────────────────────────────┘  │
│         ↓                                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Builders                                                 │  │
│  │  ┌────────────────┐  ┌─────────────────────────────┐    │  │
│  │  │ Xcode Project  │  │ Swift Package (SPM)         │    │  │
│  │  │ • Archiver     │  │ • Swift Builder             │    │  │
│  │  │ • Cleaner      │  │ • Framework Slice Builder   │    │  │
│  │  │ • XCFramework  │  │ • XCFramework Builder       │    │  │
│  │  └────────────────┘  │ • Resource Bundle Handler  │    │  │
│  │                       │ • Bundle.module Override    │    │  │
│  │                       └─────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
│         ↓                                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Platform Abstraction                                     │  │
│  │  • ios, ios-simulator                                     │  │
│  │  • SDKs, deployment targets, destinations                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│         ↓                                                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Apple Tools                                              │  │
│  │  • xcodebuild (archive, -create-xcframework)             │  │
│  │  • swift build (SPM compilation)                          │  │
│  │  • libtool (static library creation)                     │  │
│  │  • lipo (fat binary creation)                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│         ↓                                                         │
│  📦 Output: .xcframework                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📁 Module Structure (as implemented)

```
lib/xcframework_cli/
│
├── cli/                        # Thor CLI entry
│   ├── runner.rb               # commands & global flags
│   └── commands/
│       ├── build.rb            # Xcode project build
│       └── spm.rb              # Swift Package build
│
├── builder/                    # Build orchestration
│   ├── orchestrator.rb         # clean → archive(s) → xcframework
│   ├── cleaner.rb              # artifact cleanup / output dirs
│   ├── archiver.rb             # xcodebuild archive per platform
│   └── xcframework.rb          # xcodebuild -create-xcframework
│
├── spm/                        # Swift Package Manager path
│   ├── package.rb              # dump-package parsing helpers
│   ├── framework_slice.rb      # build .framework for one SDK
│   └── xcframework_builder.rb  # assemble xcframework from slices
│
├── swift/                      # Swift build helpers
│   ├── builder.rb              # runs swift build for target+SDK
│   └── sdk.rb                  # SDK abstraction (triple, paths)
│
├── platform/                   # Platform definitions
│   ├── registry.rb             # factory for supported platforms
│   ├── base.rb                 # abstract platform
│   ├── ios.rb                  # iOS device
│   └── ios_simulator.rb        # iOS Simulator
│
├── config/                     # Configuration
│   ├── loader.rb               # load YAML/JSON, apply defaults
│   ├── schema.rb               # dry-validation contract
│   └── defaults.rb             # defaults (build, archs, targets)
│
├── xcodebuild/                 # Xcode tool wrapper
│   ├── wrapper.rb              # archive/create-xcframework
│   ├── formatter.rb            # optional output formatting
│   └── result.rb               # encapsulated result
│
└── utils/                      # Utilities
    ├── logger.rb               # colored logging
    ├── spinner.rb              # progress indicators
    └── template.rb             # ERB-backed templates
```

---

## 🔄 Build Flows

### Xcode Project Build (`xckit build`)

```
1) Load & validate config (file or CLI)
2) Clean artifacts (optional)
3) Archive per platform (ios, ios-simulator)
4) Create xcframework (includes dSYMs if available)
5) Report success/errors and artifact paths
```

### Swift Package Build (`xckit spm build [targets…]`)

```
1) Validate Package.swift exists
2) Infer targets (or use provided)
3) For each SDK of requested platforms:
   • swift build (library evolution on by default)
   • Detect resource bundles (Package_Target.bundle)
   • If bundle exists:
     ✓ Render resource_bundle_accessor.swift template
     ✓ Compile accessor to .o file (swiftc -emit-object)
     ✓ Include .o in libtool static library
     ✓ Copy bundle to .framework directory
     ✓ Resolve symlinks for distribution
   • Create .framework structure:
     ✓ Binary via libtool (including accessor .o if present)
     ✓ Headers, modulemap, Info.plist
     ✓ swiftmodule files
4) For multi-arch SDKs, lipo frameworks into fat binary
5) xcodebuild -create-xcframework for resulting frameworks
6) Report xcframework paths per target
```

---

## 📦 Resource Bundle Implementation (SPM)

**Status**: ✅ **Fully Implemented** in `SPM::FrameworkSlice` (171+ lines)

### Workflow

```
1. Detection
   └─ Check for .build/<triple>/<config>/PackageName_TargetName.bundle

2. Accessor Template Rendering
   └─ Generate resource_bundle_accessor.swift with:
      • PACKAGE_NAME (from swift package dump-package)
      • TARGET_NAME (from build context)
      • MODULE_NAME (from target)

3. Compilation
   └─ swiftc -emit-object resource_bundle_accessor.swift -o accessor.o

4. Binary Inclusion
   └─ libtool -static -o Framework *.o (includes accessor.o)

5. Bundle Copying
   └─ cp -r bundle.bundle Framework.framework/

6. Symlink Resolution
   └─ Resolve all symlinks to real files for distribution

7. Multi-Arch Handling
   └─ Copy bundle from first slice to combined framework
```

### Key Features

- **Automatic detection**: Via Package.swift manifest parsing
- **Custom Bundle.module**: Replaces SPM's default accessor
- **Distribution-ready**: Symlinks resolved to real files
- **Multi-architecture**: Bundle preserved in lipo operations
- **Template-based**: ERB templates for Swift/ObjC accessors

See `lib/xcframework_cli/spm/framework_slice.rb` and `docs/RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md` for details.

---

## 🎨 Design Patterns Actually Used

- Factory: `Platform::Registry.create` for platform objects
- Composition: `Orchestrator` coordinates `Cleaner`, `Archiver`, `XCFramework`
- Templates: plist/modulemap/resource accessor rendered via `Utils::Template`

---

## 🔒 Error Handling

- Error hierarchy in `lib/xcframework_cli/errors.rb` (ConfigError, ValidationError, BuildError, PlatformError, ResourceError, PublishError stubs)
- CLI surfaces suggestions when errors carry them

---

## ✅ Supported vs 🚧 Not Yet

### ✅ **Fully Implemented**
- Platforms: `ios`, `ios-simulator`
- Commands: `build`, `spm build`, `version`, `help`
- Resource bundles: Full SPM support with Bundle.module override
- Build flows: Xcode projects + Swift Packages
- Configuration: YAML/JSON with validation
- Output formatting: xcbeautify/xcpretty integration

### 🚧 **Planned (Not Yet Implemented)**
- Additional platforms: macOS, tvOS, watchOS, visionOS, catalyst
- Publishing: Artifactory integration, Git tagging
- Additional commands: `init`, `clean`, `validate`, `platforms`
- Advanced features: Parallel builds, caching, checksums
- Error parsing: Enhanced xcodebuild error messages

---

## 🔬 Testing (repo today)

- RSpec suites under `spec/unit` and `spec/integration`
- No bundled coverage report; run `bundle exec rspec` locally for verification

---

**Last Updated**: December 9, 2025
**Reflects**: Current repository state with resource bundle implementation complete

Update this document when new commands, platforms, or features are added.
