# Error Handling

Comprehensive error guidance system.

---

## Overview

All errors inherit from `XCFrameworkCLI::Error` with helpful suggestions

```ruby
module XCFrameworkCLI
  class Error < StandardError
    attr_reader :suggestions

    def initialize(message, suggestions: [])
      @suggestions = suggestions
      super(message)
    end
  end
end
```

---

## Error Types

| Error Class | When Raised |
|-------------|-------------|
| `ConfigError` | Invalid configuration |
| `ValidationError` | Schema validation fails |
| `BuildError` | Build process fails |
| `PlatformError` | Unsupported platform |
| `ResourceError` | Bundle issues |

---

## Error Display

Errors show:
- Error message
- Actionable suggestions
- Recovery options

```bash
Error: Invalid platform: ios-macos

Suggestions:
  - Use 'ios' or 'ios-simulator'
  - Run 'xckit platforms' to see available platforms

Try: xckit build --platforms ios ios-simulator
```

---

## Common Errors

### Configuration Errors

**Missing config file**
```
Error: Configuration file not found

Suggestions:
  - Create .xcframework.yml in your project root
  - Run 'xckit init' to generate a template
  - Specify path with --config /path/to/config.yml
```

**Invalid platform**
```
Error: Invalid platform: mac

Suggestions:
  - Use 'ios' or 'ios-simulator'
  - Supported: ios, ios-simulator
  - Check for typos in platform name
```

### Build Errors

**Archive creation failed**
```
Error: Failed to create archive for iOS

Suggestions:
  - Check that Xcode project opens correctly
  - Verify scheme exists in project
  - Ensure valid code signing is configured
  - Check Xcode build logs for details
```

**XCFramework assembly failed**
```
Error: Failed to create XCFramework

Suggestions:
  - Verify all archives were created successfully
  - Check for framework conflicts in archives
  - Ensure frameworks are properly signed
  - Check available disk space
```

---

## Getting Help

```bash
# Show all commands
./bin/xckit help

# Show command help
./bin/xckit build --help

# Show version
./bin/xckit version
```
