# 🚀 Deployment Guide - XCFramework CLI

This guide walks you through publishing XCFramework CLI for your internal team with Homebrew-style installation.

---

## 📋 Table of Contents

1. [Pre-Publishing Checklist](#pre-publishing-checklist)
2. [Publishing Methods](#publishing-methods)
3. [Installation for Team Members](#installation-for-team-members)
4. [Updating Versions](#updating-versions)
5. [Troubleshooting](#troubleshooting)

---

## ✅ Pre-Publishing Checklist

Before publishing, ensure these files are ready:

- [x] **LICENSE** - MIT License created
- [x] **xcframework-cli.gemspec** - Updated with correct GitHub repo URL
- [x] **install.sh** - Updated with correct repo path
- [x] **.github/workflows/release.yml** - GitHub Actions workflow for releases

---

## 🎯 Publishing Methods

### Method 1: GitHub Releases (Recommended for Internal Teams)

This is the **simplest method** - no external registry needed!

#### Step 1: Build and Test Locally

```bash
# Make sure all tests pass
bundle exec rake spec

# Build the gem
gem build xcframework-cli.gemspec

# This creates: xcframework-cli-0.1.0.gem
```

#### Step 2: Create a Git Tag

```bash
# Commit all changes first
git add .
git commit -m "Release v0.1.0"

# Create and push tag
git tag v0.1.0
git push origin main
git push origin v0.1.0
```

#### Step 3: GitHub Actions Automatically:

The workflow (`.github/workflows/release.yml`) will:

1. ✅ Run tests
2. ✅ Build the gem
3. ✅ Create a GitHub Release
4. ✅ Attach the `.gem` file

#### Step 4: Verify Release

Go to: `https://github.com/phuongddx/xcframework-cli/releases`

You should see:

- Version tag (v0.1.0)
- Release notes
- Attached gem file: `xcframework-cli-0.1.0.gem`

---

### Method 2: GitHub Packages (Optional)

For more control over access and versioning:

#### Step 1: Create Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - ✅ `write:packages`
   - ✅ `read:packages`
   - ✅ `delete:packages` (optional)
4. Copy the token (you'll need it for publishing)

#### Step 2: Configure RubyGems Credentials

```bash
# Add GitHub Packages as gem source
mkdir -p ~/.gem
cat > ~/.gem/credentials << EOF
---
:github: Bearer YOUR_GITHUB_TOKEN_HERE
EOF

chmod 0600 ~/.gem/credentials
```

#### Step 3: Publish to GitHub Packages

```bash
# Build the gem
gem build xcframework-cli.gemspec

# Publish to GitHub Packages
gem push --key github \
  --host https://rubygems.pkg.github.com/phuongddx \
  xcframework-cli-0.1.0.gem
```

---

## 👥 Installation for Team Members

Share this one-liner with your team:

### Option A: Install via Script (Recommended)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phuongddx/xcframework-cli/main/install.sh)"
```

**What it does:**

1. ✅ Checks Ruby version (requires 3.0+)
2. ✅ Downloads latest release from GitHub
3. ✅ Installs gem to `~/.xcframework-cli`
4. ✅ Adds to PATH automatically
5. ✅ Verifies installation

**After installation:**

```bash
# Reload shell
source ~/.zshrc  # or ~/.bashrc

# Verify installation
xckit version
xckit --help
```

### Option B: Manual Installation

If team members prefer manual installation:

```bash
# Download the gem from releases page
curl -L -o xcframework-cli-0.1.0.gem \
  https://github.com/phuongddx/xcframework-cli/releases/download/v0.1.0/xcframework-cli-0.1.0.gem

# Install locally
gem install xcframework-cli-0.1.0.gem --install-dir ~/.xcframework-cli

# Add to PATH (add this to ~/.zshrc or ~/.bashrc)
export PATH="$HOME/.xcframework-cli/bin:$PATH"
```

### Option C: Install from GitHub Packages

If you published to GitHub Packages:

```bash
# Configure gem source (one-time setup)
gem sources --add https://rubygems.pkg.github.com/phuongddx

# Create credentials file with GitHub token
mkdir -p ~/.gem
cat > ~/.gem/credentials << EOF
---
:github: Bearer TEAM_MEMBER_GITHUB_TOKEN
EOF
chmod 0600 ~/.gem/credentials

# Install the gem
gem install xcframework-cli --source https://rubygems.pkg.github.com/phuongddx
```

---

## 🔄 Updating Versions

### Releasing a New Version

1. **Update version number**

```bash
# Edit lib/xcframework_cli/version.rb
VERSION = '0.2.0'  # Increment version
```

2. **Update changelog**

```bash
# Add entry to docs/CHANGELOG.md
## [0.2.0] - 2025-12-10

### Added
- New feature X
- New feature Y

### Fixed
- Bug fix Z
```

3. **Commit and tag**

```bash
git add lib/xcframework_cli/version.rb docs/CHANGELOG.md
git commit -m "Bump version to 0.2.0"
git tag v0.2.0
git push origin main
git push origin v0.2.0
```

4. **GitHub Actions creates release automatically**

### Team Members Update

```bash
# Reinstall with same command
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phuongddx/xcframework-cli/main/install.sh)"
```

The script automatically detects and installs the latest version.

---

## 🔧 Troubleshooting

### Issue: Ruby Version Too Old

```bash
# Error: Ruby 3.0.0 or higher is required

# Solution: Update Ruby via Homebrew (macOS)
brew install ruby
```

### Issue: Command Not Found After Installation

```bash
# Error: xckit: command not found

# Solution 1: Reload shell
source ~/.zshrc  # or ~/.bashrc

# Solution 2: Manually add to PATH
export PATH="$HOME/.xcframework-cli/bin:$PATH"

# Solution 3: Verify installation directory
ls -la ~/.xcframework-cli/bin/xckit
```

### Issue: Permission Denied

```bash
# Error: Permission denied when installing

# Solution: Use user gem directory (default in our script)
gem install xcframework-cli-0.1.0.gem --install-dir ~/.xcframework-cli --no-document
```

### Issue: Can't Download from GitHub

```bash
# Error: Failed to download gem

# Solution 1: Check GitHub is accessible
curl -I https://github.com/phuongddx/xcframework-cli

# Solution 2: Download manually from releases page
# Visit: https://github.com/phuongddx/xcframework-cli/releases
# Download the .gem file
# Install: gem install ./xcframework-cli-0.1.0.gem --install-dir ~/.xcframework-cli
```

### Issue: Gem Build Fails

```bash
# Error during gem build

# Solution: Install dependencies
bundle install
bundle exec rake spec  # Verify tests pass
gem build xcframework-cli.gemspec
```

---

## 📊 Version Strategy

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., 0.1.0)
- **MAJOR**: Breaking changes (1.0.0 when production-ready)
- **MINOR**: New features, backward compatible (0.2.0)
- **PATCH**: Bug fixes (0.1.1)

### Pre-release Versions

For beta testing:

```bash
VERSION = '0.2.0-beta1'  # First beta
VERSION = '0.2.0-beta2'  # Second beta
VERSION = '0.2.0-rc1'    # Release candidate
VERSION = '0.2.0'        # Stable release
```

---

## 🔒 Private Repository Considerations

If your repository is **private**:

### For Team Members to Install:

**Option 1: Use SSH URLs (Recommended)**

Update `install.sh` to use SSH:

```bash
git clone git@github.com:phuongddx/xcframework-cli.git .
```

Team members need SSH keys configured.

**Option 2: Use Personal Access Tokens**

```bash
# Team member sets environment variable
export GITHUB_TOKEN=their_personal_token

# Modified install.sh uses token:
git clone https://$GITHUB_TOKEN@github.com/phuongddx/xcframework-cli.git .
```

**Option 3: Grant Read Access**

Add team members as collaborators:

1. Go to: `https://github.com/phuongddx/xcframework-cli/settings/access`
2. Invite team members
3. They can now download releases

---

## 📝 Quick Reference

### One-Liner Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phuongddx/xcframework-cli/main/install.sh)"
```

### Verify Installation

```bash
xckit version
```

### Update to Latest

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phuongddx/xcframework-cli/main/install.sh)"
```

### Uninstall

```bash
rm -rf ~/.xcframework-cli
# Remove from PATH in ~/.zshrc or ~/.bashrc
```

---

## 🎉 Next Steps

After successful deployment:

1. ✅ Share installation command with team
2. ✅ Create internal documentation/wiki page
3. ✅ Set up Slack/Teams channel for support
4. ✅ Gather feedback for v0.2.0
5. ✅ Consider adding more platforms (macOS, tvOS, etc.)

---

## 📞 Support

For issues or questions:

- 🐛 File issues: https://github.com/phuongddx/xcframework-cli/issues
- 📧 Email: phuong.doan@aavn.com
- 📖 Documentation: https://github.com/phuongddx/xcframework-cli/tree/main/docs

---

**Happy Building! 🛠️**
