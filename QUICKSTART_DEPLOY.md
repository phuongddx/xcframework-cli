# 🚀 Quick Start - Publishing XCFramework CLI

## Step-by-Step Deployment (5 Minutes)

### 1. Pre-flight Check ✅

All files are ready:

- ✅ `LICENSE` - MIT License
- ✅ `xcframework-cli.gemspec` - Updated with correct repo URL
- ✅ `install.sh` - Homebrew-style installer
- ✅ `.github/workflows/release.yml` - Auto-release workflow

### 2. Build and Test Locally

```bash
# Run tests
bundle exec rake spec

# Build gem
gem build xcframework-cli.gemspec

# You should see: xcframework-cli-0.1.0.gem
```

### 3. Create First Release

```bash
# Commit everything
git add .
git commit -m "Release v0.1.0 - Initial public release"

# Push to GitHub
git push origin main

# Create and push tag
git tag v0.1.0
git push origin v0.1.0
```

### 4. Wait for GitHub Actions (2-3 minutes)

- Go to: https://github.com/phuongddx/xcframework-cli/actions
- Watch the "Release" workflow run
- When complete, check: https://github.com/phuongddx/xcframework-cli/releases

### 5. Share with Your Team! 🎉

Send this to your team:

```
🎉 XCFramework CLI is now available!

Install with one command:

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phuongddx/xcframework-cli/main/install.sh)"

Usage:
xckit build --project MySDK.xcodeproj --scheme MySDK --platforms ios ios-simulator

Documentation: https://github.com/phuongddx/xcframework-cli
```

---

## Testing Installation

Before sharing with team, test the installation:

```bash
# Test in a clean environment (new terminal)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phuongddx/xcframework-cli/main/install.sh)"

# Verify
xckit version
# Should output: XCFramework CLI 0.1.0

xckit --help
# Should show help menu
```

---

## What Happens Behind the Scenes

When someone runs your install command:

1. **Downloads** `install.sh` from your GitHub repo
2. **Checks** Ruby version (requires 3.0+)
3. **Fetches** latest release from GitHub Releases API
4. **Downloads** the `.gem` file from release assets
5. **Installs** to `~/.xcframework-cli`
6. **Updates** PATH in shell config (`.zshrc` or `.bashrc`)
7. **Verifies** installation by checking `xckit` command

---

## Troubleshooting

### If Release Workflow Fails

Check these:

1. GitHub Actions enabled? (Settings → Actions)
2. Tag format correct? (must be `v0.1.0` format)
3. Tests passing? (`bundle exec rake spec`)

### If Installation Fails for Team Members

**Ruby version issue:**

```bash
# Install Ruby 3.0+ via Homebrew
brew install ruby
```

**Permission issue:**

```bash
# Use user directory (default in our script)
gem install --user-install xcframework-cli-0.1.0.gem
```

**PATH not updated:**

```bash
# Manually add to ~/.zshrc or ~/.bashrc
export PATH="$HOME/.xcframework-cli/bin:$PATH"
source ~/.zshrc
```

---

## Next Release (v0.2.0)

When ready to release updates:

```bash
# 1. Update version
# Edit: lib/xcframework_cli/version.rb
VERSION = '0.2.0'

# 2. Update changelog
# Edit: docs/CHANGELOG.md

# 3. Commit and tag
git add .
git commit -m "Release v0.2.0"
git tag v0.2.0
git push origin main
git push origin v0.2.0

# 4. Team members update with same command
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phuongddx/xcframework-cli/main/install.sh)"
```

---

## Need Help?

📖 **Full Guide**: See `DEPLOYMENT.md` for detailed instructions
🐛 **Issues**: https://github.com/phuongddx/xcframework-cli/issues
📧 **Contact**: phuong.doan@aavn.com

---

**That's it! Your tool is now deployable with a single command, just like Homebrew! 🍺**
