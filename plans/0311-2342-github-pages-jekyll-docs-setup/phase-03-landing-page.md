# Phase 03 — Landing Page (index.md)

**Status:** ✅ Complete
**Effort:** ~15 min

## Overview

Create `docs/index.md` as the site home page. Synthesize key content from `INDEX.md` and the project README — concise, user-facing, no internal dev notes.

## Target Content

```markdown
---
title: Home
nav_order: 1
---

# XCFramework CLI

> Build XCFrameworks from Xcode projects or Swift Packages across Apple platforms.

[![Ruby Version](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org/)
[![Version](https://img.shields.io/badge/version-0.2.0-blue.svg)](https://github.com/phuongddx/xcframework-cli)
[![Tests](https://img.shields.io/badge/tests-280%2B%20passing-success.svg)](https://github.com/phuongddx/xcframework-cli/tree/main/spec)

**Status:** ✅ Production Ready for iOS | 🚧 Other platforms in development

---

## What is XCFramework CLI?

XCFramework CLI automates XCFramework creation from Xcode projects and Swift Packages.
It handles multi-platform builds, custom configurations, and resource management through
simple YAML/JSON config files and CLI commands.

**Perfect for:**
- Publishing framework libraries across Apple platforms
- Distributing SDKs with resource bundles (fonts, images, themes)
- Automating CI/CD pipelines for framework distribution
- Managing complex build settings per platform

---

## Quick Start

### Install

```bash
git clone https://github.com/phuongddx/xcframework-cli.git
cd xcframework-cli
bundle install
./bin/xckit version
```

**Requirements:** Ruby 3.0+, Xcode 12+, Bundler

### Build from Xcode Project

```bash
./bin/xckit build --config .xcframework.yml --verbose
```

### Build from Swift Package

```bash
./bin/xckit spm build --package-dir . --platforms ios ios-simulator
```

---

## Features

| Feature | Status |
|---------|--------|
| Xcode Projects (`.xcodeproj` / `.xcworkspace`) | ✅ |
| Swift Packages (`Package.swift`) | ✅ |
| iOS Device + Simulator | ✅ |
| Resource Bundles (fonts, images, JSON) | ✅ |
| YAML/JSON Configuration | ✅ |
| Custom Build Settings | ✅ |
| Colored build output (`xcbeautify`) | ✅ |
| macOS, tvOS, watchOS, visionOS, Catalyst | 🚧 Phase 2 |

---

## Project Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1: Foundation | iOS/iOS Simulator | ✅ Complete |
| 2: Platform Expansion | macOS, tvOS, watchOS, visionOS | 🚧 Q1-Q2 2026 |
| 3: Resource Management | Advanced bundle handling | 📋 Q2 2026 |
| 4: Publishing Pipeline | Distribution automation | 📋 Q2-Q3 2026 |

See the [Roadmap]({% link project-roadmap.md %}) for details.
```

## Implementation Steps

1. Create `docs/index.md` with above content
2. Verify badges point to correct GitHub URLs
3. Ensure `{% link %}` tags reference correct filenames

## Todo

- [x] Create `docs/index.md`
- [x] Verify badge URLs
- [x] Test `{% link %}` references locally
