# Publishing Plan: XCFramework CLI via GitHub Packages

**Goal**: Publish xckit to GitHub Packages for controlled distribution
**Target**: GitHub Packages (https://github.com/features/packages)
**Timeline**: 4-6 hours

**Benefits of GitHub-First Approach**:
- ✅ More control over distribution
- ✅ Can keep it semi-private or fully public
- ✅ Integrated with your existing repo
- ✅ Easy to test with specific users
- ✅ Can expand to RubyGems.org later
- ✅ GitHub Actions for automated publishing

---

## Phase 1: Pre-Publishing Preparation

### 1.1 License Selection (Still Important!)

Even for GitHub Packages, you need a license:

**Recommended**: **MIT License** (for public distribution)

**If keeping private initially**: Can use "Proprietary" temporarily

**Action**:
```bash
# I'll create MIT license for you
# Or you can choose another
```

---

### 1.2 Update Gemspec

**File**: `xckit.gemspec`

**Required Changes**:
```ruby
# Update repository URL to match actual location
spec.homepage = 'https://github.com/phuongddx/xckit'
spec.metadata['source_code_uri'] = 'https://github.com/phuongddx/xckit'
spec.metadata['changelog_uri'] = 'https://github.com/phuongddx/xckit/blob/main/docs/CHANGELOG.md'
spec.metadata['bug_tracker_uri'] = 'https://github.com/phuongddx/xckit/issues'

# License can be MIT or keep Proprietary if private
spec.license = 'MIT'  # or 'Proprietary'
```

---

### 1.3 Quality Assurance

```bash
# Run all tests
bundle exec rake spec
# Expected: ✅ 109 tests passing

# Check code quality
bundle exec rake rubocop
# Expected: ✅ Clean or minimal offenses

# Verify gem builds correctly
gem build xckit.gemspec
# Expected: ✅ Successfully built RubyGem
```

---

## Phase 2: GitHub Packages Setup

### 2.1 Create Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a name: `xckit-packages`
4. Select scopes:
   - ✅ `write:packages` - Upload packages
   - ✅ `read:packages` - Download packages
   - ✅ `delete:packages` - Delete packages (optional)
5. Click **"Generate token"**
6. **COPY THE TOKEN** (you won't see it again!)

**Save token securely**:
```bash
# Store in environment variable
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Or save to file (don't commit!)
echo "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx" > ~/.github_token
chmod 600 ~/.github_token
```

### 2.2 Configure RubyGems Credentials

```bash
# Create or edit ~/.gem/credentials
mkdir -p ~/.gem

cat >> ~/.gem/credentials <<EOF
---
:github: Bearer YOUR_GITHUB_TOKEN_HERE
EOF

# Secure the file
chmod 600 ~/.gem/credentials
```

---

## Phase 3: Prepare for Publishing

### 3.1 Create `.gemrc` Configuration

**Create** `.gemrc` in your home directory:

```bash
cat > ~/.gemrc <<'EOF'
---
:backtrace: false
:bulk_threshold: 1000
:sources:
- https://rubygems.org/
- https://rubygems.pkg.github.com/phuongddx
:update_sources: true
:verbose: true
EOF
```

### 3.2 Update Version (if needed)

**File**: `lib/xcframework_cli/version.rb`

```ruby
module XCFrameworkCLI
  VERSION = '0.1.0'  # Current version

  # For pre-release testing, could use:
  # VERSION = '0.1.0.pre1'
  # VERSION = '0.1.0.beta1'
end
```

### 3.3 Build the Gem

```bash
# Clean previous builds
rm -f *.gem

# Build gem
gem build xckit.gemspec

# Verify gem was created
ls -lh xckit-*.gem
# Should see: xckit-0.1.0.gem
```

---

## Phase 4: Publish to GitHub Packages

### 4.1 Push to GitHub Packages

```bash
# Set your GitHub username
export GITHUB_OWNER="phuongddx"

# Publish the gem
gem push --key github \
  --host https://rubygems.pkg.github.com/${GITHUB_OWNER} \
  xckit-0.1.0.gem
```

**Expected Output**:
```
Pushing gem to https://rubygems.pkg.github.com/phuongddx...
Successfully registered gem: xckit (0.1.0)
```

### 4.2 Verify Publication

1. Go to: https://github.com/phuongddx/xckit/packages
2. You should see **xckit** package listed
3. Click on it to see package details

---

## Phase 5: Test Installation

### 5.1 Configure User Installation

**For other users to install**, they need to:

**Step 1**: Create GitHub token (read:packages scope)

**Step 2**: Configure credentials:
```bash
mkdir -p ~/.gem
cat >> ~/.gem/credentials <<EOF
---
:github: Bearer THEIR_GITHUB_TOKEN
EOF
chmod 600 ~/.gem/credentials
```

**Step 3**: Install the gem:
```bash
gem install xckit \
  --source "https://rubygems.pkg.github.com/phuongddx"
```

### 5.2 Test Yourself

**In a new terminal**:
```bash
# Uninstall any local version first
gem uninstall xckit

# Install from GitHub Packages
gem install xckit \
  --source "https://rubygems.pkg.github.com/phuongddx"

# Test it works
xckit version
xckit help
```

---

## Phase 6: Create GitHub Release

### 6.1 Create Git Tag

```bash
# Tag the release
git tag -a v0.1.0 -m "Release v0.1.0 - Initial release via GitHub Packages"

# Push tag to GitHub
git push origin v0.1.0
```

### 6.2 Create GitHub Release

1. Go to: https://github.com/phuongddx/xckit/releases/new
2. **Choose tag**: `v0.1.0`
3. **Release title**: `v0.1.0 - Initial Release`
4. **Description**:

```markdown
## 🎉 Initial Release - GitHub Packages

XCFramework CLI is now available via GitHub Packages!

### Installation

**Prerequisites**: GitHub Personal Access Token with `read:packages` scope

**Setup**:
\`\`\`bash
# 1. Create token at: https://github.com/settings/tokens
# 2. Configure credentials:
mkdir -p ~/.gem
cat >> ~/.gem/credentials <<EOF
---
:github: Bearer YOUR_GITHUB_TOKEN
EOF
chmod 600 ~/.gem/credentials

# 3. Install gem:
gem install xckit \\
  --source "https://rubygems.pkg.github.com/phuongddx"
\`\`\`

### Features

✅ **Production-ready iOS XCFramework building**
- iOS Device (arm64)
- iOS Simulator (arm64, x86_64)

✅ **Real-time build logs** with xcbeautify/xcpretty
✅ **YAML/JSON configuration**
✅ **Comprehensive error messages**
✅ **109 tests, 68% coverage**

### Quick Start

\`\`\`bash
# Build from command line
xckit build \\
  --project MySDK.xcodeproj \\
  --scheme MySDK \\
  --framework-name MySDK

# Or use config file
xckit build --config .xcframework.yml
\`\`\`

See the [README](https://github.com/phuongddx/xckit#readme) for complete documentation.

---

**Installation help**: See [Installation Guide](#installation)
**Found a bug?**: [Report it](https://github.com/phuongddx/xckit/issues)
```

5. **Attach file**: Upload `xckit-0.1.0.gem`
6. Click **"Publish release"**

---

## Phase 7: Update Documentation

### 7.1 Update README - Installation Section

**Add to README.md** after "## Installation":

```markdown
## Installation

### Via GitHub Packages

**Prerequisites**:
- Ruby 3.0+
- GitHub account with Personal Access Token

**Step 1**: Create GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scope: `read:packages`
4. Copy the token

**Step 2**: Configure RubyGems credentials

\`\`\`bash
mkdir -p ~/.gem
cat >> ~/.gem/credentials <<EOF
---
:github: Bearer YOUR_GITHUB_TOKEN_HERE
EOF
chmod 600 ~/.gem/credentials
\`\`\`

**Step 3**: Install the gem

\`\`\`bash
gem install xckit \\
  --source "https://rubygems.pkg.github.com/phuongddx"
\`\`\`

**Step 4**: Verify installation

\`\`\`bash
xckit version
\`\`\`

### From Source (Development)

\`\`\`bash
git clone https://github.com/phuongddx/xckit.git
cd xckit
bundle install
./bin/xckit version
\`\`\`
```

### 7.2 Add Package Badge

**Add to top of README.md**:

```markdown
[![GitHub Package](https://img.shields.io/badge/GitHub-Package-blue.svg)](https://github.com/phuongddx/xckit/packages)
```

---

## Phase 8: Automated Publishing with GitHub Actions (Optional)

### 8.1 Create Workflow File

**Create**: `.github/workflows/publish.yml`

```yaml
name: Publish Gem to GitHub Packages

on:
  release:
    types: [created]

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'

      - name: Build gem
        run: gem build xckit.gemspec

      - name: Publish to GitHub Packages
        run: |
          mkdir -p ~/.gem
          cat > ~/.gem/credentials <<EOF
          ---
          :github: Bearer ${{ secrets.GITHUB_TOKEN }}
          EOF
          chmod 600 ~/.gem/credentials
          gem push --key github \
            --host https://rubygems.pkg.github.com/${{ github.repository_owner }} \
            *.gem
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Usage**: Next releases will auto-publish when you create a GitHub release!

---

## Phase 9: Share with Users

### 9.1 Create Installation Guide

**Create**: `INSTALLATION.md`

```markdown
# Installation Guide - XCFramework CLI

## For End Users

### Step 1: Create GitHub Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name it: "RubyGems GitHub Packages"
4. Select scope: **read:packages**
5. Click "Generate token"
6. **Copy the token** (you won't see it again)

### Step 2: Configure Credentials

\`\`\`bash
mkdir -p ~/.gem
cat >> ~/.gem/credentials <<'EOF'
---
:github: Bearer YOUR_TOKEN_HERE
EOF
chmod 600 ~/.gem/credentials
\`\`\`

⚠️ **Replace** \`YOUR_TOKEN_HERE\` with your actual token!

### Step 3: Install

\`\`\`bash
gem install xckit \\
  --source "https://rubygems.pkg.github.com/phuongddx"
\`\`\`

### Step 4: Verify

\`\`\`bash
xckit --version
# Should output: XCFramework CLI v0.1.0
\`\`\`

## Troubleshooting

**Error: "Could not find a valid gem"**
- Check your token has \`read:packages\` scope
- Verify credentials file at \`~/.gem/credentials\`

**Error: "401 Unauthorized"**
- Your token may have expired
- Create a new token and update credentials

**Error: "403 Forbidden"**
- Repository might be private
- Ensure you have access to the repository
```

---

## Migration to RubyGems.org (Future)

When ready to publish to RubyGems.org (worldwide):

1. **Create RubyGems account**: https://rubygems.org/sign_up
2. **Update license** to MIT (if not already)
3. **Publish to RubyGems**:
   ```bash
   gem push xckit-0.1.0.gem
   ```
4. **Users can then install** simply with:
   ```bash
   gem install xckit
   # No GitHub token needed!
   ```

---

## Quick Reference Commands

```bash
# Build gem
gem build xckit.gemspec

# Publish to GitHub Packages
gem push --key github \
  --host https://rubygems.pkg.github.com/phuongddx \
  xckit-0.1.0.gem

# Install from GitHub Packages
gem install xckit \
  --source "https://rubygems.pkg.github.com/phuongddx"

# Uninstall
gem uninstall xckit

# List installed version
gem list xckit
```

---

## Security Best Practices

### For You (Publisher):
- ✅ Use token with minimal scopes (only write:packages)
- ✅ Never commit tokens to git
- ✅ Rotate tokens periodically
- ✅ Use GitHub Actions secrets for automation

### For Users:
- ✅ Use token with only read:packages scope
- ✅ Store credentials securely (chmod 600)
- ✅ Don't share your personal access token
- ✅ Create project-specific tokens when possible

---

## Timeline Estimate

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 1**: Preparation | 30-60 min | License, gemspec, QA |
| **Phase 2**: GitHub Setup | 15 min | Create token, configure |
| **Phase 3**: Build Gem | 15 min | Build and verify |
| **Phase 4**: Publish | 15 min | Push to GitHub Packages |
| **Phase 5**: Test | 30 min | Install and verify |
| **Phase 6**: Release | 30 min | Tag, create release |
| **Phase 7**: Documentation | 45 min | Update README, guides |
| **Phase 8**: Automation (optional) | 30 min | GitHub Actions |

**Total**: 4-6 hours for complete process

---

## Next Steps

1. **Confirm decisions**:
   - License type (MIT recommended)
   - Keep at phuongddx/xckit (✅ already correct)

2. **I will**:
   - Update gemspec with correct URLs
   - Create LICENSE file
   - Run QA checks

3. **You will**:
   - Create GitHub Personal Access Token
   - Configure credentials
   - Test the installation process

4. **Together**:
   - Publish to GitHub Packages
   - Create release
   - Update documentation

**Ready to start?** 🚀
