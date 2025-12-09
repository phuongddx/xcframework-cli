# Local Installation Guide

Test xckit in your project before publishing!

**Target Project**: `/Users/ddphuong/Projects/epost-workspace/muji-workspace/epost-ios-theme-ui`

---

## Method 1: Use from Source (Recommended for Development)

This is the easiest way to test and make changes on the fly.

### Step 1: In Your iOS Project

**Navigate to your project**:
```bash
cd /Users/ddphuong/Projects/epost-workspace/muji-workspace/epost-ios-theme-ui
```

**Create or edit `Gemfile`**:
```ruby
source 'https://rubygems.org'

# Local development - use xckit from source
gem 'xckit', path: '/Users/ddphuong/Projects/xckit'

# Other gems you might have
# gem 'cocoapods'
# gem 'fastlane'
```

**Install**:
```bash
bundle install
```

**Use it**:
```bash
# Via bundle exec
bundle exec xckit version
bundle exec xckit help

# Build your framework
bundle exec xckit build \
  --project YourProject.xcodeproj \
  --scheme YourScheme \
  --framework-name YourFramework
```

### Advantages ✅
- Changes in xckit immediately available
- No need to rebuild gem
- Easy to debug
- Can modify code while testing

### When to Use
- ✅ Active development
- ✅ Testing new features
- ✅ Debugging issues

---

## Method 2: Install Built Gem Locally

Install the gem system-wide from the built .gem file.

### Step 1: Build the Gem

**In xckit directory**:
```bash
cd /Users/ddphuong/Projects/xckit

# Build gem
gem build xckit.gemspec
# Creates: xckit-0.1.0.gem
```

### Step 2: Install Locally

```bash
# Install the gem
gem install ./xckit-0.1.0.gem
```

### Step 3: Use in Your Project

**Now you can use it directly** (no bundle exec needed):

```bash
cd /Users/ddphuong/Projects/epost-workspace/muji-workspace/epost-ios-theme-ui

# Use directly
xckit version
xckit build --project ...
```

### Or via Bundler

**In your project's Gemfile**:
```ruby
source 'https://rubygems.org'

# Installed gem (not from source)
gem 'xckit', '0.1.0'
```

### Advantages ✅
- Tests actual gem installation
- Simulates end-user experience
- System-wide availability

### When to Use
- ✅ Final testing before publish
- ✅ Simulating real installation
- ✅ Verifying gem packaging

---

## Method 3: Use Specific Local Gem File

Point Gemfile to the specific .gem file.

**In your project's Gemfile**:
```ruby
source 'https://rubygems.org'

# Use local gem file
gem 'xckit', path: '/Users/ddphuong/Projects/xckit'
# OR from built gem
# gem 'xckit', path: '/Users/ddphuong/Projects/xckit/xckit-0.1.0.gem'
```

---

## Quick Setup Script

Create this script to quickly test in your project:

**Create**: `test-in-project.sh` in xckit directory

```bash
#!/bin/bash
set -e

PROJECT_DIR="/Users/ddphuong/Projects/epost-workspace/muji-workspace/epost-ios-theme-ui"
GEM_DIR="/Users/ddphuong/Projects/xckit"

echo "🔨 Building gem..."
cd "$GEM_DIR"
gem build xckit.gemspec

echo "📦 Installing gem locally..."
gem install ./xckit-0.1.0.gem

echo "✅ Installed! Testing..."
xckit version

echo "📝 Creating test Gemfile in project..."
cd "$PROJECT_DIR"

cat > Gemfile.test <<EOF
source 'https://rubygems.org'
gem 'xckit', '0.1.0'
EOF

echo "🧪 Testing bundle install..."
bundle install --gemfile=Gemfile.test

echo "✅ All done! You can now use:"
echo "   xckit version"
echo "   xckit help"
```

**Make executable and run**:
```bash
chmod +x test-in-project.sh
./test-in-project.sh
```

---

## Complete Test Workflow

### 1. Initial Setup (One Time)

```bash
# In your iOS project
cd /Users/ddphuong/Projects/epost-workspace/muji-workspace/epost-ios-theme-ui

# Create Gemfile
cat > Gemfile <<'EOF'
source 'https://rubygems.org'

# Use xckit from local source
gem 'xckit', path: '/Users/ddphuong/Projects/xckit'
EOF

# Install
bundle install
```

### 2. Test Basic Functionality

```bash
# Check version
bundle exec xckit version
# Expected: XCFramework CLI v0.1.0

# Check help
bundle exec xckit help
# Expected: Command list

# Test build (if you have a framework to build)
bundle exec xckit build \
  --project YourProject.xcodeproj \
  --scheme YourFramework \
  --framework-name YourFramework \
  --output build/test
```

### 3. Test with Config File

**Create**: `.xcframework.yml` in your iOS project

```yaml
project:
  name: YourProject
  xcode_project: YourProject.xcodeproj

frameworks:
  - name: YourFramework
    scheme: YourFramework
    platforms:
      - ios
      - ios-simulator
    deployment_targets:
      ios: "14.0"

build:
  output_dir: build
  clean_before_build: true
  verbose: true              # See build logs!
  use_formatter: true        # Pretty output
```

**Test**:
```bash
bundle exec xckit build --config .xcframework.yml
```

### 4. Verify Output

```bash
# Check built framework
ls -la build/
# Should see:
# - YourFramework.xcframework/
# - YourFramework-iOS.xcarchive/
# - YourFramework-iOS-Simulator.xcarchive/

# Verify architectures
lipo -info build/YourFramework.xcframework/ios-arm64/YourFramework.framework/YourFramework
# Should show: arm64

lipo -info build/YourFramework.xcframework/ios-arm64_x86_64-simulator/YourFramework.framework/YourFramework
# Should show: arm64 x86_64
```

---

## Uninstall (If Needed)

### Remove installed gem
```bash
gem uninstall xckit
```

### Remove from project
```bash
cd /Users/ddphuong/Projects/epost-workspace/muji-workspace/epost-ios-theme-ui
rm Gemfile Gemfile.lock
```

---

## Troubleshooting

### Issue: "Gem not found"

**Solution**: Make sure path is correct
```bash
# Check gem exists
ls /Users/ddphuong/Projects/xckit/xckit.gemspec
# Should exist
```

### Issue: "Command not found: xckit"

**Solutions**:
```bash
# If using Gemfile path method:
bundle exec xckit version  # ✅ Correct

# If installed system-wide:
xckit version  # ✅ Correct

# If using source in Gemfile:
bundle exec xckit version  # ✅ Must use bundle exec
```

### Issue: "Wrong version"

**Solution**: Uninstall and reinstall
```bash
gem uninstall xckit
gem install /Users/ddphuong/Projects/xckit/xckit-0.1.0.gem
```

### Issue: "Changes not reflecting"

**If using Method 1** (source path):
- Changes are immediate, just run again

**If using Method 2** (installed gem):
- Need to rebuild and reinstall:
  ```bash
  cd /Users/ddphuong/Projects/xckit
  gem build xckit.gemspec
  gem install ./xckit-0.1.0.gem
  ```

---

## Testing Checklist

Before publishing, test these in your real project:

- [ ] ✅ Gem installs without errors
- [ ] ✅ Version command works
- [ ] ✅ Help command shows all options
- [ ] ✅ Build command works with CLI args
- [ ] ✅ Build command works with config file
- [ ] ✅ Verbose mode shows xcodebuild output
- [ ] ✅ XCFramework is created successfully
- [ ] ✅ Architectures are correct (lipo -info)
- [ ] ✅ dSYM files are included
- [ ] ✅ Error messages are helpful
- [ ] ✅ Works with your actual project structure

---

## Recommended Workflow

**For Active Development**:
```bash
# Use Method 1 (source path)
# In your iOS project Gemfile:
gem 'xckit', path: '/Users/ddphuong/Projects/xckit'

# Edit code in xckit
# Test immediately in your project
bundle exec xckit build ...
```

**For Final Testing**:
```bash
# Use Method 2 (built gem)
cd /Users/ddphuong/Projects/xckit
gem build xckit.gemspec
gem install ./xckit-0.1.0.gem

# Test as end user would use it
cd /Users/ddphuong/Projects/epost-workspace/muji-workspace/epost-ios-theme-ui
xckit build ...
```

---

## Next Steps After Local Testing

Once you've verified it works in your real project:

1. ✅ **Document any issues** you found
2. ✅ **Fix any bugs** discovered
3. ✅ **Update documentation** based on real usage
4. ✅ **Commit all changes**
5. 🚀 **Proceed with publishing** to GitHub Packages

---

**Ready to test locally?** Choose your method and let me know if you need help! 🎯
