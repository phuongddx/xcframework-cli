# Migration Guide: Framework-Agnostic Configuration

This guide helps you migrate from the old hardcoded configuration to the new framework-agnostic setup.

## What Changed?

The XCFramework CLI tools have been updated to be **completely framework-agnostic**. All hardcoded references to specific projects (ePostSDK, luz_epost_ios, etc.) have been removed and replaced with configurable variables.

## Summary of Changes

### 1. `config.sh`
**Before:**
- Hardcoded `EPOST_SDK_NAME="ePostSDK"`
- Hardcoded `PUSH_NOTIFICATION_SDK_NAME="ePostPushNotificationSDK"`
- Hardcoded `IOS_PROJECT_FILE="${IOS_PROJECT}/luz_epost_ios.xcodeproj"`
- Hardcoded `EPOSTSDK_SOURCE="${WORKSPACE_ROOT}/ePostSDK"`

**After:**
- Configurable `XCODE_PROJECT_NAME` (via environment variable)
- Configurable `DEFAULT_FRAMEWORKS` (via `FRAMEWORK_NAMES` environment variable)
- Configurable `SDK_OUTPUT_DIR_NAME` (via environment variable)
- All paths derived from configuration variables

### 2. `inject-resource-accessor.sh`
**Before:**
- Hardcoded search for `ios_theme_ui.build` artifacts
- Hardcoded module name `"ios_theme_ui"` in compilation

**After:**
- Accepts `MODULE_NAME` parameter (optional)
- Uses `RESOURCE_MODULE_NAME` from config if not provided
- Skips injection if no module name specified

### 3. `debug.sh`
**Before:**
- Hardcoded to build `ePostSDK` and `ePostPushNotificationSDK`
- No command-line arguments for framework names

**After:**
- Accepts framework names as command-line arguments
- Falls back to `DEFAULT_FRAMEWORKS` from config
- Builds any number of frameworks in a loop

### 4. `release.sh`
**Before:**
- Hardcoded to build and publish `ePostSDK` and `ePostPushNotificationSDK`

**After:**
- Accepts framework names as command-line arguments
- Falls back to `DEFAULT_FRAMEWORKS` from config
- Builds any number of frameworks in a loop

### 5. `setup.sh`
**Before:**
- Header: "Setup Build Tools for ePost iOS"

**After:**
- Header: "Setup Build Tools for XCFramework CLI"

### 6. `publish_to_artifactory.sh`
**Before:**
- Hardcoded `FRAMEWORK_NAME="${EPOST_SDK_NAME}"`
- Hardcoded package ID: `axon.ePostSDK`
- Hardcoded git branch: `master`
- Hardcoded Bitbucket references

**After:**
- Accepts framework name as argument
- Configurable `PACKAGE_SCOPE` environment variable
- Package ID: `${PACKAGE_SCOPE}.${FRAMEWORK_NAME}`
- Configurable `GIT_BRANCH` environment variable
- Generic git references (not Bitbucket-specific)
- Optional Slack notifications
- Validates required environment variables

## Migration Steps

### For ePost Project (Maintain Current Behavior)

To keep the same behavior as before, set these environment variables:

```bash
export XCODE_PROJECT_NAME="luz_epost_ios"
export FRAMEWORK_NAMES="ePostSDK ePostPushNotificationSDK"
export SDK_OUTPUT_DIR_NAME="ePostSDK"
export RESOURCE_MODULE_NAME="ios_theme_ui"
```

Or create a `config.local.sh`:

```bash
#!/usr/bin/env bash
export XCODE_PROJECT_NAME="luz_epost_ios"
export FRAMEWORK_NAMES="ePostSDK ePostPushNotificationSDK"
export SDK_OUTPUT_DIR_NAME="ePostSDK"
export RESOURCE_MODULE_NAME="ios_theme_ui"
```

Then source it:
```bash
source config.local.sh
./debug.sh --all
```

### For New Projects

1. Copy the example configuration:
   ```bash
   cp config.example.sh config.local.sh
   ```

2. Edit `config.local.sh` with your project details:
   ```bash
   export XCODE_PROJECT_NAME="YourProject"
   export FRAMEWORK_NAMES="YourSDK"
   export SDK_OUTPUT_DIR_NAME="SDKs"
   ```

3. Use the scripts:
   ```bash
   source config.local.sh
   ./debug.sh --simulator
   ```

## Publishing Configuration

For Artifactory publishing, you now need to set these environment variables:

```bash
export VERSION="1.0.0"
export ARTIFACTORY_URL="https://your-artifactory.com/artifactory/api/swift"
export ARTIFACTORY_USERNAME="your-username"
export JFROG_ACCESS_TOKEN="your-token"
export PACKAGE_SCOPE="com.yourcompany"  # NEW: replaces hardcoded "axon"
```

## Backward Compatibility

The scripts maintain backward compatibility through environment variables. If you set the appropriate environment variables, the scripts will behave exactly as before.

## Benefits of New Configuration

1. **Reusable**: Use the same scripts for any iOS XCFramework project
2. **Flexible**: Configure via environment variables or config files
3. **CI/CD Friendly**: Easy to configure in different environments
4. **No Code Changes**: Change configuration without modifying scripts
5. **Multi-Project**: Support multiple projects with different configurations

## Troubleshooting

### "No frameworks specified and DEFAULT_FRAMEWORKS is not set"

Set the `FRAMEWORK_NAMES` environment variable:
```bash
export FRAMEWORK_NAMES="YourSDK"
```

### "Xcode project not found"

Set the correct project name:
```bash
export XCODE_PROJECT_NAME="YourActualProjectName"
```

### Publishing fails with package ID error

Make sure to set `PACKAGE_SCOPE`:
```bash
export PACKAGE_SCOPE="com.yourcompany"
```

## See Also

- [CONFIGURATION.md](CONFIGURATION.md) - Complete configuration guide
- [config.example.sh](config.example.sh) - Example configuration file
- [README.md](README.md) - Main project documentation

