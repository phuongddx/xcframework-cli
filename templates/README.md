# Resource Bundle Accessor Templates

## Overview

This directory contains templates for custom resource bundle accessors used when building XCFrameworks that embed ios_theme_ui.

## Files

### resource_bundle_accessor.swift

**Purpose:** Override SPM's auto-generated resource bundle accessor to support XCFramework distribution.

**Problem it solves:**
- SPM auto-generates `resource_bundle_accessor.swift` that only searches standard locations (Bundle.main, Bundle.module)
- When ios_theme_ui is embedded in an XCFramework, resources are copied into the embedding framework
- The auto-generated accessor cannot find resources in these non-standard locations
- This template adds extended search paths specific to XCFramework distribution

**Usage:**

```bash
# In XCFramework build script (e.g., build_theme_showcase_xcframework.sh):

# 1. Find SPM's auto-generated resource_bundle_accessor.swift
accessor_file=$(find "$OUTPUT_DIR" -name "resource_bundle_accessor.swift" | head -1)

# 2. Replace with custom template
cp scripts/templates/resource_bundle_accessor.swift "$accessor_file"

# 3. Recompile the .o file with swiftc
swiftc -emit-library -emit-object \
    -module-name "ios_theme_ui" \
    -target "arm64-apple-ios16.0" \
    -sdk "$sdk_path" \
    -o "$object_file" \
    "$accessor_file"
```

**Used by:**
- **ThemeShowcaseSDK XCFramework** (`ios_theme_showcase/build_theme_showcase_xcframework.sh`)
- Any future XCFramework that embeds ios_theme_ui

**Bundle name:** `ios_theme_ui_ios_theme_ui.bundle`

**Bundle contents:**
- **Fonts:** SwissPostSans-Regular.otf, SwissPostSans-Bold.otf, SwissPostSans-Black.otf (~220KB)
- **Assets:** Compiled assets (Assets.car) (~91KB)
- **Themes:** JSON theme configuration files
- **Total:** ~311KB

## Search Strategy

The template implements a priority-based search through multiple locations:

1. **Bundle(for: BundleFinder.self).bundleURL** ⭐ Primary
   - Finds bundle copied directly into embedding framework
   - Example: `ThemeShowcaseSDK.framework/ios_theme_ui_ios_theme_ui.bundle`

2. **Bundle.main.resourceURL**
   - SPM source builds where bundle is in main bundle resources

3. **Bundle(for: BundleFinder.self).resourceURL**
   - Bundle relative to current class

4. **Bundle.main.bundleURL**
   - Main bundle URL fallback

5. **Bundle.main.bundleURL/Frameworks/[EmbeddingFramework].framework/**
   - App's Frameworks directory (when app imports XCFramework)

6. **Bundle.main.bundleURL/Frameworks/ios_theme_ui.framework/**
   - Standalone ios_theme_ui XCFramework distribution

## Implementation Details

**How it works:**

1. **Build time:** XCFramework build script copies `ios_theme_ui_ios_theme_ui.bundle` into embedding framework
2. **Runtime:** `Bundle(for: BundleFinder.self)` resolves to the embedding framework
3. **Resolution:** Template appends bundle name to framework URL and loads resources

**Why it's needed:**

```swift
// ❌ SPM's auto-generated version only searches:
Bundle.main.resourceURL  // Not in main bundle
Bundle.module            // Not available in XCFramework

// ✅ Custom template adds:
Bundle(for: BundleFinder.self).bundleURL  // Finds it here!
```

## Maintenance

When updating this template:

1. **Test with all consuming XCFrameworks:**
   ```bash
   cd ios_theme_showcase
   ./build_theme_showcase_xcframework.sh --no-parallel
   ```

2. **Verify bundle resolution at runtime:**
   ```bash
   cd post-shell-app
   make run  # Should not crash with "unable to find bundle"
   ```

3. **Update documentation in consuming build scripts:**
   - `ios_theme_showcase/build_theme_showcase_xcframework.sh`
   - `ios_theme_showcase/docs/XCFramework-Resource-Bundle-Fix.md`

## Technical Background

**Related Documentation:**
- [XCFramework Resource Bundle Fix](../../ios_theme_showcase/docs/XCFramework-Resource-Bundle-Fix.md)
- [xccache project](https://github.com/trinhngocthuyen/xccache) (inspiration for this approach)

**Key Concepts:**
- **SPM Resource Bundles:** Swift Package Manager automatically generates resource bundles for packages with resources
- **XCFramework Distribution:** Pre-compiled binary framework format supporting multiple platforms
- **Transitive Dependencies:** ios_theme_ui embedded in another framework (ThemeShowcaseSDK)
- **Bundle Resolution:** Runtime mechanism for locating resource bundles via Bundle API

## Troubleshooting

### Error: "unable to find bundle named ios_theme_ui_ios_theme_ui"

**Cause:** Resource bundle not copied into embedding XCFramework during build

**Fix:**
1. Verify bundle exists in build artifacts: `find build -name "ios_theme_ui_ios_theme_ui.bundle"`
2. Ensure build script copies bundle into framework
3. Check XCFramework structure: `tree -L 4 ThemeShowcaseSDK.xcframework/`

### Error: "Template not found at: ../epost-ios-theme-ui/scripts/templates/resource_bundle_accessor.swift"

**Cause:** epost-ios-theme-ui submodule not initialized

**Fix:**
```bash
cd muji-workspace
make init  # Initialize all submodules
```

### Build succeeds but runtime still crashes

**Cause:** Template was not injected during build, or .o file not recompiled

**Fix:**
1. Check build logs for "Injecting custom resource accessor" message
2. Verify template was copied: `ls -la build/DerivedData/.../resource_bundle_accessor.swift`
3. Ensure .o file was recompiled after template injection
