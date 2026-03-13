# Resource Bundles

Handle resources in your frameworks.

---

## Overview

Resource bundles contain non-code assets like:
- Fonts (.ttf, .otf)
- Images (.png, .jpg)
- Configuration files (.json, .plist)
- Localized strings

---

## SPM Resource Bundles

### Automatic Detection

The tool automatically detects bundles at build time

```
.build/<triple>/release/PackageName_TargetName.bundle
```

### Bundle.module Generation

When a bundle is found, a custom accessor is generated

```swift
// Auto-generated during build
import Foundation

private class BundleFinder {}

extension BundleFinder {
  static var module: Bundle {
    Bundle(url: Bundle.main.bundleURL
      .appendingPathComponent("PackageName_TargetName.bundle"))
  }
}

extension Bundle {
  static var module: Bundle { BundleFinder.module }
}
```

### Usage in Code

```swift
// In your framework code
let fontURL = Bundle.module.url(forResource: "MyFont.ttf")
let configFile = Bundle.module.url(forResource: "config.json")
```

---

## Manual Configuration

### Environment Variable

```bash
export RESOURCE_MODULE_NAME="my_module_name"
./bin/xckit spm build --package-dir .
```

### In Config File

```yaml
spm:
  package_dir: "."
  resource_module_name: "my_module_name"
```

---

## Supported Resource Types

| Type | Extension | Example |
|------|----------|---------|
| Fonts | .ttf, .otf | CustomFont-Regular.ttf |
| Images | .png, .jpg, .svg | logo@2x.png |
| JSON | .json | settings.json |
| Plists | .plist | Info.plist |
| Strings | .strings | Localizable.strings |

---

## Best Practices

1. **Keep bundles small** - Only include necessary resources
2. **Use standard naming** - Match target name
3. **Test bundle access** - Verify Bundle.module works
4. **Document resources** - List available resources

