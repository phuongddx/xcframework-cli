# Publishing Plan: XCFramework CLI to RubyGems

**Goal**: Publish xckit as a public Ruby gem for worldwide distribution
**Target**: RubyGems.org (https://rubygems.org)
**Timeline**: 1-2 days

---

## Phase 1: Pre-Publishing Preparation

### 1.1 License Selection ⚠️ **IMPORTANT**

**Current Status**: Gemspec says "Proprietary" - Need to decide on public license

**Options**:
- **MIT License** (Recommended) - Very permissive, most common for Ruby gems
- **Apache 2.0** - Similar to MIT but with patent protection
- **GPL v3** - Copyleft license (requires derivative works to be open source)
- **Keep Proprietary** - Private gem distribution only

**Action Required**:
```bash
# Choose license and create LICENSE file
# Example for MIT:
cp templates/LICENSE.MIT LICENSE

# Update gemspec:
spec.license = 'MIT'  # or 'Apache-2.0' or 'GPL-3.0'
```

**Decision Needed**: Which license? 🤔

---

### 1.2 Update Gemspec for Public Release

**File**: `xckit.gemspec`

**Current Issues**:
```ruby
spec.license       = 'Proprietary'  # ❌ Change to public license
spec.homepage      = 'https://github.com/aavn/xckit'  # ❌ Update URL
```

**Required Changes**:
```ruby
spec.license       = 'MIT'  # ✅ Public license
spec.homepage      = 'https://github.com/phuongddx/xckit'  # ✅ Correct URL
spec.metadata['source_code_uri'] = 'https://github.com/phuongddx/xckit'
spec.metadata['changelog_uri'] = 'https://github.com/phuongddx/xckit/blob/main/docs/CHANGELOG.md'
spec.metadata['bug_tracker_uri'] = 'https://github.com/phuongddx/xckit/issues'
spec.metadata['documentation_uri'] = 'https://github.com/phuongddx/xckit'
```

**Verify**:
- [ ] All URLs point to correct repository
- [ ] License is appropriate for public use
- [ ] Metadata is complete
- [ ] Required files are included in `spec.files`

---

### 1.3 Quality Assurance

#### Run Full Test Suite
```bash
# All tests must pass
bundle exec rake spec

# Check coverage (should be 60%+)
open coverage/index.html
```

**Expected**: ✅ 109 tests passing, 0 failures

#### Check Code Quality
```bash
# RuboCop should have minimal violations
bundle exec rake rubocop

# Auto-fix what can be fixed
bundle exec rake lint_fix
```

**Expected**: ✅ Clean or minimal offenses

#### Verify Gem Contents
```bash
# Build gem locally
gem build xckit.gemspec

# Inspect gem contents
gem unpack xckit-0.1.0.gem
ls xckit-0.1.0/
```

**Verify includes**:
- [ ] All Ruby files in `lib/`
- [ ] Executable in `bin/`
- [ ] Example configs in `config/examples/`
- [ ] README.md, CHANGELOG.md, LICENSE
- [ ] **NOT** included: specs/, coverage/, .git/

---

## Phase 2: RubyGems Account Setup

### 2.1 Create RubyGems Account

**If you don't have one**:
1. Go to https://rubygems.org/sign_up
2. Create account
3. Verify email

**If you already have one**:
```bash
# Check credentials
gem signin
```

### 2.2 Configure API Key

```bash
# First time setup
gem signin

# Or manually configure
# Credentials stored in: ~/.gem/credentials
```

---

## Phase 3: Test Locally

### 3.1 Build and Install Locally

```bash
# Build gem
gem build xckit.gemspec

# Install locally
gem install ./xckit-0.1.0.gem

# Test installation
xckit version
xckit help
```

### 3.2 Test in Clean Environment

**Using Docker** (recommended):
```bash
# Create test Dockerfile
cat > Dockerfile.test <<'EOF'
FROM ruby:3.2
RUN apt-get update && apt-get install -y git
WORKDIR /test
COPY xckit-0.1.0.gem .
RUN gem install xckit-0.1.0.gem
CMD ["xckit", "version"]
EOF

# Build and test
docker build -f Dockerfile.test -t xcframework-test .
docker run xcframework-test
```

**Manual Testing**:
```bash
# In new terminal/directory
gem install /path/to/xckit-0.1.0.gem
cd /tmp/test-project
xckit build --help
```

---

## Phase 4: Publish to RubyGems

### 4.1 Final Pre-Publish Checklist

- [ ] All tests passing
- [ ] RuboCop clean
- [ ] LICENSE file exists
- [ ] Gemspec has correct license
- [ ] README has installation instructions for `gem install`
- [ ] Version is correct (0.1.0)
- [ ] Changelog is updated
- [ ] Git is clean (no uncommitted changes)
- [ ] Latest code pushed to GitHub

### 4.2 Create Git Tag

```bash
# Tag the release
git tag -a v0.1.0 -m "Release v0.1.0 - Initial public release"

# Push tag
git push origin v0.1.0
```

### 4.3 Publish Gem

```bash
# Build final gem
gem build xckit.gemspec

# Publish to RubyGems.org
gem push xckit-0.1.0.gem
```

**Expected Output**:
```
Pushing gem to https://rubygems.org...
Successfully registered gem: xckit (0.1.0)
```

### 4.4 Verify Publication

```bash
# Wait 1-2 minutes, then check
gem search xckit -r

# Try installing from RubyGems
gem install xckit

# Test
xckit version
```

---

## Phase 5: Post-Publishing

### 5.1 Create GitHub Release

1. Go to: https://github.com/phuongddx/xckit/releases/new
2. Select tag: `v0.1.0`
3. Title: `v0.1.0 - Initial Public Release`
4. Description:

```markdown
## 🎉 Initial Public Release

XCFramework CLI is now available as a Ruby gem!

### Installation

\`\`\`bash
gem install xckit
\`\`\`

### Features

✅ Production-ready iOS XCFramework building
- iOS Device (arm64)
- iOS Simulator (arm64, x86_64)

✅ Real-time build logs with xcbeautify/xcpretty
✅ YAML/JSON configuration
✅ Comprehensive error messages
✅ 109 tests, 68% coverage

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
```

5. Attach: `xckit-0.1.0.gem` file

### 5.2 Update README Badges

Add RubyGems badge to README:

```markdown
[![Gem Version](https://badge.fury.io/rb/xckit.svg)](https://badge.fury.io/rb/xckit)
[![Downloads](https://img.shields.io/gem/dt/xckit.svg)](https://rubygems.org/gems/xckit)
```

### 5.3 Update Installation Instructions

Update README.md "Installation" section:

```markdown
## Installation

### Via RubyGems (Recommended)

\`\`\`bash
gem install xckit
\`\`\`

### Via Bundler

Add to your Gemfile:

\`\`\`ruby
gem 'xckit'
\`\`\`

Then run:

\`\`\`bash
bundle install
\`\`\`

### From Source

\`\`\`bash
git clone https://github.com/phuongddx/xckit.git
cd xckit
bundle install
./bin/xckit version
\`\`\`
```

---

## Phase 6: Announcement & Monitoring

### 6.1 Announcement Channels

**GitHub**:
- ✅ Release created with notes
- Pin repository to profile

**Social/Community** (Optional):
- Ruby Weekly newsletter
- Reddit r/ruby
- Twitter/X announcement
- Dev.to article

### 6.2 Monitoring

**First Week**:
- Monitor GitHub issues
- Check RubyGems download stats: https://rubygems.org/gems/xckit
- Respond to questions/issues promptly

**Ongoing**:
- Set up GitHub notifications
- Monitor gem download trends
- Plan future releases

---

## Important Considerations

### ⚠️ Critical Decisions Needed

1. **License Choice** - Must decide before publishing
   - Recommendation: **MIT** (most permissive, standard for Ruby gems)
   - Alternative: **Apache 2.0** (if you want patent protection)

2. **Organization vs Personal**
   - Current URL: `phuongddx/xckit`
   - Consider: Move to organization? `aavn/xckit`?

3. **Copyright Statement**
   - Current: "© 2025 AAVN. All rights reserved."
   - Should match license choice

### 🔒 Security Considerations

- **Never commit** RubyGems API keys
- Enable **2FA** on RubyGems account
- Enable **MFA requirement** in gemspec (already done ✅)
- Monitor for **dependency vulnerabilities**

### 📊 Success Metrics

**Week 1 Targets**:
- [ ] Successful publication
- [ ] 10+ downloads
- [ ] 0 critical issues
- [ ] Installation works on macOS 11+

**Month 1 Targets**:
- [ ] 100+ downloads
- [ ] 1+ GitHub stars
- [ ] Documentation feedback incorporated
- [ ] Any bugs fixed

---

## Rollback Plan

If issues are found after publishing:

```bash
# Yank specific version (makes it unavailable)
gem yank xckit -v 0.1.0

# Fix issues, bump version to 0.1.1
# Publish fixed version
gem push xckit-0.1.1.gem
```

**Note**: Yanked versions can't be re-pushed. Must use new version number.

---

## Quick Reference Commands

```bash
# Build
gem build xckit.gemspec

# Test locally
gem install ./xckit-0.1.0.gem --local

# Publish
gem push xckit-0.1.0.gem

# Tag release
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0

# Check stats
open https://rubygems.org/gems/xckit
```

---

## Timeline Estimate

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 1**: Preparation | 2-4 hours | License, gemspec, QA |
| **Phase 2**: Account Setup | 15 minutes | RubyGems account |
| **Phase 3**: Local Testing | 1-2 hours | Build, test, verify |
| **Phase 4**: Publishing | 30 minutes | Tag, push, publish |
| **Phase 5**: Post-Publishing | 1-2 hours | Release, docs, badges |
| **Phase 6**: Monitoring | Ongoing | Issues, feedback |

**Total**: 1-2 days for complete process

---

## Next Steps

1. **Review this plan** and decide on:
   - License type
   - Repository ownership (personal vs org)
   - Copyright statement

2. **Execute Phase 1** (Preparation)
   - Add LICENSE file
   - Update gemspec
   - Run QA checks

3. **Proceed through phases** systematically

4. **Celebrate! 🎉** when gem is live on RubyGems.org

---

**Questions?** Ask before proceeding with any phase!
