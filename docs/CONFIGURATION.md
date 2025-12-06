# Configuration Guide

This guide explains how to configure the XCFramework CLI tools for your iOS project.

## Quick Start

The tools are now **framework-agnostic** and can be used with any iOS XCFramework project. No hardcoded project names!

### Option 1: Environment Variables (Recommended)

Set environment variables before running scripts:

```bash
export XCODE_PROJECT_NAME="MyProject"
export FRAMEWORK_NAMES="MySDK AnotherSDK"
./debug.sh --simulator
```

### Option 2: Configuration File

1. Copy the example configuration:
   ```bash
   cp config.example.sh config.local.sh
   ```

2. Edit `config.local.sh` with your project details

3. Source it before running scripts:
   ```bash
   source config.local.sh
   ./debug.sh --all
   ```

### Option 3: Command-Line Arguments

Pass framework names directly to scripts:

```bash
./debug.sh MySDK AnotherSDK --simulator
./release.sh MySDK AnotherSDK
```

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `XCODE_PROJECT_NAME` | Xcode project name (without .xcodeproj) | `"MyiOSApp"` |
| `FRAMEWORK_NAMES` | Space-separated framework names | `"MySDK UtilsSDK"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SDK_OUTPUT_DIR_NAME` | Output directory for XCFrameworks | `"SDKOutput"` |
| `RESOURCE_MODULE_NAME` | Module name for resource bundles | `""` (disabled) |
| `DEBUG_CONFIG` | Print config when sourcing | `"0"` |

### Publishing Variables (for Artifactory)

| Variable | Description | Required |
|----------|-------------|----------|
| `VERSION` | Version to publish | Yes |
| `ARTIFACTORY_URL` | Artifactory registry URL | Yes |
| `ARTIFACTORY_USERNAME` | Artifactory username | Yes |
| `JFROG_ACCESS_TOKEN` | JFrog access token | Yes |
| `PACKAGE_SCOPE` | Package scope (e.g., "com.company") | Yes |
| `GIT_BRANCH` | Git branch for releases | No (default: "master") |
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | No |

## Usage Examples

### Example 1: Build Single Framework

```bash
export XCODE_PROJECT_NAME="MyApp"
./debug.sh MySDK --simulator
```

### Example 2: Build Multiple Frameworks

```bash
export XCODE_PROJECT_NAME="CompanyApp"
export FRAMEWORK_NAMES="CoreSDK NetworkSDK UISDK"
./debug.sh --all  # Builds all frameworks from FRAMEWORK_NAMES
```

### Example 3: Build Specific Frameworks

```bash
# Build only CoreSDK and UISDK, ignore NetworkSDK
./debug.sh CoreSDK UISDK --device
```

### Example 4: Release Build with Publishing

```bash
export XCODE_PROJECT_NAME="ProductApp"
export VERSION="2.1.0"
export ARTIFACTORY_URL="https://company.jfrog.io/artifactory/api/swift"
export ARTIFACTORY_USERNAME="ci-user"
export JFROG_ACCESS_TOKEN="your-token"
export PACKAGE_SCOPE="com.company.product"

./release.sh MySDK
```

### Example 5: Resource Bundle Injection

If your framework uses SPM resource bundles:

```bash
export XCODE_PROJECT_NAME="MyApp"
export RESOURCE_MODULE_NAME="my_theme_ui"
./debug.sh MySDK --all
```

## Script Reference

### `debug.sh`

Build frameworks for development/testing.

```bash
./debug.sh [FRAMEWORK_NAMES...] [OPTIONS]

Options:
  --all         Build for device + simulator (default)
  --device      Build for device only
  --simulator   Build for simulator only
  --help        Show help
```

### `release.sh`

Build and publish frameworks for release.

```bash
./release.sh [FRAMEWORK_NAMES...]
```

### `create-xcframework.sh`

Low-level build script (called by debug.sh and release.sh).

```bash
./create-xcframework.sh FRAMEWORK_NAME [OPTIONS]

Options:
  --all           Build for both platforms
  --device        Device only
  --simulator     Simulator only
  --output-dir    Custom output directory
  --no-clean      Skip cleaning
  --verbose       Verbose output
  --checksum      Generate SHA256 checksum
```

### `publish_to_artifactory.sh`

Publish a framework to Artifactory.

```bash
./publish_to_artifactory.sh [FRAMEWORK_NAME]
```

## Migration from Hardcoded Configuration

If you're migrating from the old ePost-specific configuration:

### Old Way (Hardcoded)
```bash
# config.sh had:
EPOST_SDK_NAME="ePostSDK"
PUSH_NOTIFICATION_SDK_NAME="ePostPushNotificationSDK"
```

### New Way (Configurable)
```bash
# Set via environment:
export FRAMEWORK_NAMES="ePostSDK ePostPushNotificationSDK"
export XCODE_PROJECT_NAME="luz_epost_ios"
export SDK_OUTPUT_DIR_NAME="ePostSDK"
```

## Troubleshooting

### "No frameworks specified and DEFAULT_FRAMEWORKS is not set"

**Solution**: Either pass framework names as arguments or set `FRAMEWORK_NAMES`:
```bash
export FRAMEWORK_NAMES="MySDK"
# or
./debug.sh MySDK --all
```

### "Xcode project not found"

**Solution**: Set the correct project name:
```bash
export XCODE_PROJECT_NAME="YourActualProjectName"
```

### Resource accessor not injecting

**Solution**: Set the module name:
```bash
export RESOURCE_MODULE_NAME="your_module_name"
```

## Best Practices

1. **Use environment variables** for CI/CD pipelines
2. **Use config.local.sh** for local development (add to .gitignore)
3. **Keep secrets secure** - never commit `JFROG_ACCESS_TOKEN`
4. **Use semantic versioning** for `VERSION`
5. **Test with --simulator** first before building for device

## See Also

- [config.example.sh](config.example.sh) - Example configuration file
- [README.md](README.md) - Main project documentation

