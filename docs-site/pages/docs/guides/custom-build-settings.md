# Custom Build Settings

Pass custom xcodebuild flags to your builds.

---

## Basic Usage

Add custom settings in your `build.build_settings` section

```yaml
build:
  configuration: "Release"
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    EXCLUDED_ARCHS: "x86_64"
    ENABLE_BITCODE: "NO"
```

All settings are passed directly to xcodebuild as `KEY="VALUE"`.

---

## Common Use Cases

### 1. Swift Module Interface Errors

**Problem:** Build fails with "module interface is invalid" errors.

**Solution:**
```yaml
build_settings:
  OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
```

### 2. Exclude Simulator Architectures

**Problem:** Need arm64-only simulator builds for M1 mac compatibility.

**Solution:**
```yaml
frameworks:
  - name: "MySDK"
    platforms: [ios, ios-simulator]
    architectures:
      ios-simulator: [arm64]  # Exclude x86_64
```

### 3. Disable Bitcode

**Problem:** Bitcode deprecated in modern Xcode.

**Solution:**
```yaml
build_settings:
  ENABLE_BITCODE: "NO"
```

### 4. Custom Deployment Targets

**Problem:** Need higher minimum iOS version for specific APIs.

**Solution:**
```yaml
frameworks:
  - name: "MySDK"
    platforms: [ios, ios-simulator]
    deployment_targets:
      ios: "15.0"
      ios-simulator: "15.0"
```

---

## Platform-Specific Settings

You can override settings per platform

```yaml
frameworks:
  - name: "MySDK"
    platforms: [ios, ios-simulator]
    architectures:
      ios: [arm64]
      ios-simulator: [arm64, x86_64]
    deployment_targets:
      ios: "14.0"
      ios-simulator: "15.0"
```

---

## Complete Example

```yaml
project:
  name: "MySDK"
  xcode_project: "MySDK.xcodeproj"

frameworks:
  - name: "MySDK"
    scheme: "MySDK"
    platforms: [ios, ios-simulator]
    architectures:
      ios: [arm64]
      ios-simulator: [arm64]  # Remove x86_64 for faster builds
    deployment_targets:
      ios: "15.0"  # Higher for new APIs

build:
  configuration: "Release"
  output_dir: "build"
  clean_before_build: true
  build_settings:
    OTHER_SWIFT_FLAGS: "-no-verify-emitted-module-interface"
    ENABLE_BITCODE: "NO"
    SWIFT_OPTIMIZATION_LEVEL: "-O"
```
