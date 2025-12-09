# XCFramework CLI - Architecture Overview

Current, code-accurate view of the Ruby CLI that ships in this repo.

---

## 🏛️ High-Level Architecture

```
┌──────────────────────────────────────────────────────┐
│                      CLI Layer                       │
│        Thor commands: build, spm build, version      │
└──────────────────────────┬───────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│                 Configuration Layer                   │
│     YAML/JSON load + defaults + schema validation     │
└──────────────────────────┬───────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────┐
│                Orchestration Layer                   │
│    Clean → Archive (per platform) → XCFramework      │
└──────────────┬───────────────┬───────────────────────┘
               │               │
               ▼               ▼
         Platform Registry   Xcodebuild Wrapper
         (ios, ios-simulator)    (archive/create-xcframework)
```

---

## 📦 Module Breakdown (implemented)

### 1) CLI (`lib/xcframework_cli/cli/runner.rb`, `bin/xckit`)

- Commands: `build`, `spm build`, `version`, `help`
- Global flags: `--verbose`, `--quiet`

### 2) Configuration (`lib/xcframework_cli/config/`)

- `loader.rb` – finds/loads YAML or JSON, applies defaults, validates
- `schema.rb` – dry-validation contract
- `defaults.rb` – build/platform defaults (deployment targets, architectures)
- Supported files: `.xcframework.yml/.yaml/.json`

### 3) Platform (`lib/xcframework_cli/platform/`)

- `base.rb`, `ios.rb`, `ios_simulator.rb`, `registry.rb`
- Supported identifiers: `ios`, `ios-simulator`
- Registry helpers: `create`, `valid?`, `all_platforms`, `all_instances`, `platform_info`

### 4) Builder (`lib/xcframework_cli/builder/`)

- `orchestrator.rb` – clean (optional) → build archives → create xcframework
- `archiver.rb` – wraps `xcodebuild archive` per platform
- `xcframework.rb` – wraps `xcodebuild -create-xcframework`
- `cleaner.rb` – removes artifacts and prepares output dirs

### 5) Xcodebuild wrapper (`lib/xcframework_cli/xcodebuild/`)

- `wrapper.rb` – executes archive/create-xcframework commands
- `formatter.rb`, `result.rb` – optional formatting/result helpers

### 6) Swift Package path (`lib/xcframework_cli/spm/`)

- `package.rb`, `framework_slice.rb`, `xcframework_builder.rb`
- Builds slices with `swift build` + `libtool`, then assembles via `-create-xcframework`
- Resource bundle handling lives inside `framework_slice.rb` (override `resource_bundle_accessor`, copy bundle)

### 7) Utils

- `utils/logger.rb`, `utils/spinner.rb`, `utils/template.rb`

---

## 🔄 Build Flows (implemented)

### Xcode project build (`xckit build`)

```
Config load/validate → optional clean → archive each platform
  (ios, ios-simulator) → create xcframework → report paths/errors
```

### Swift Package build (`xckit spm build [targets…]`)

```
Validate Package.swift → infer targets → build slices per SDK with swift build
→ combine (lipo for multi-arch) → xcodebuild -create-xcframework
```

---

## 🎨 Patterns in use

- Factory: `Platform::Registry.create`
- Composition: `Orchestrator` calls `Cleaner`, `Archiver`, `XCFramework`
- Templates: plist/modulemap/resource accessor rendering via `Utils::Template`

---

## 🚧 Not currently implemented (avoid assuming)

- Commands: `publish`, `init`, `clean` standalone, `validate`, `platforms`
- Platforms: macOS, tvOS, watchOS, visionOS, catalyst, etc.
- Modules: dedicated resource manager, publisher, notifier, git tagger
- Features: parallel builds, caching, checksum generation, env-var merging, xcodebuild error parser

---

## 🔒 Error Handling

- Error classes in `lib/xcframework_cli/errors.rb` (ConfigError, ValidationError, BuildError, PlatformError, ResourceError, PublishError stubs)
- CLI shows suggestions when provided by raised errors

---

Scope reminder: update this overview alongside new platforms/commands/features.
