# Phase 01 — Jekyll Configuration

**Status:** ✅ Complete
**Effort:** ~20 min

## Overview

Create Jekyll configuration files in `docs/` to enable GitHub Pages with just-the-docs theme.

## Files to Create

### `docs/_config.yml`

```yaml
title: XCFramework CLI
description: Build XCFrameworks across all Apple platforms — iOS, macOS, tvOS, watchOS, visionOS, Catalyst
theme: just-the-docs

baseurl: /xcframework-cli
url: https://phuongddx.github.io

color_scheme: dark

# Search
search_enabled: true
search:
  heading_level: 2
  previews: 3

# Navigation
nav_sort: case_insensitive
nav_external_links:
  - title: GitHub
    url: https://github.com/phuongddx/xcframework-cli
  - title: Issues
    url: https://github.com/phuongddx/xcframework-cli/issues

# Footer
footer_content: "XCFramework CLI — MIT Licensed"

# Exclude internal files from the site
exclude:
  - Gemfile
  - Gemfile.lock
  - README.md
  - INDEX.md
  - RESOURCE_BUNDLE_IMPLEMENTATION_PLAN.md
  - RESOURCE_BUNDLE_STRUCTURE_COMPARISON.md

# Jekyll settings
kramdown:
  syntax_highlighter_opts:
    block:
      line_numbers: false

# Callouts (just-the-docs v0.6+)
callouts:
  note:
    color: blue
  warning:
    color: yellow
  tip:
    color: green
```

### `docs/Gemfile`

```ruby
source "https://rubygems.org"

gem "just-the-docs", "~> 0.10"
gem "github-pages", group: :jekyll_plugins
```

## Implementation Steps

1. Create `docs/_config.yml` with above content
2. Create `docs/Gemfile` for local development
3. Update root `.gitignore` to exclude `docs/_site/` and `docs/.jekyll-cache/`

## Todo

- [x] Create `docs/_config.yml`
- [x] Create `docs/Gemfile`
- [x] Update `.gitignore`

## Verification

Local preview:
```bash
cd docs
bundle install
bundle exec jekyll serve
# Open http://localhost:4000/xcframework-cli
```
