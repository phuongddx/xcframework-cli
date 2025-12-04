# XCFramework CLI Tools

Build automation tools for creating ePost iOS XCFrameworks.

## Quick Start

```bash
# Build for simulator (fast, for local development)
make debug-simulator

# Build for device only
make debug-device

# Build for device + simulator
make debug-all

# Release build + publish to Artifactory
make release

# Clean all build artifacts
make clean
```

## Configuration

All paths and settings are centralized in `config.sh`. Scripts automatically source this file.

**Debug configuration:**
```bash
DEBUG_CONFIG=1 make debug-simulator
```

## Scripts

- `config.sh` - Centralized configuration (paths, framework names, helpers)
- `create-xcframework.sh` - Core XCFramework builder
- `release.sh` - Release workflow (build + publish)
- `debug.sh` - Debug builds with platform options
- `publish_to_artifactory.sh` - Artifactory publishing
- `copy-resource-bundle.sh` - Resource bundle management
- `inject-resource-accessor.sh` - Resource accessor injection
- `setup.sh` - Initial setup script

## Build Output

```
build/
├── DerivedData/          # Xcode build artifacts
└── logs/                 # Build logs

../ePostSDK/
├── ePostSDK/
│   └── ePostSDK.xcframework
└── ePostPushNotificationSDK/
    └── ePostPushNotificationSDK.xcframework
```

## Requirements

- Xcode 14.0+
- iOS 13.0+ deployment target
- Optional: xcbeautify or xcpretty for formatted output

## Usage from Scripts

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Now use centralized config
echo "Building to: ${BUILD_DIR}"
echo "XCFramework output: ${XCFRAMEWORK_OUTPUT_DIR}"
```
