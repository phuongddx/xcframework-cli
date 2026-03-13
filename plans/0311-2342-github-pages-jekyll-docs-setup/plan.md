---
title: GitHub Pages Jekyll Docs Setup
status: complete
created: 2026-03-11
branch: main
---

# GitHub Pages — Jekyll (just-the-docs) Documentation Site

## Overview

Set up Jekyll with just-the-docs theme on the existing `docs/` folder, deployed via GitHub Pages from `main` branch. Zero new infrastructure — GitHub auto-builds on every push.

**Target URL:** `https://phuongddx.github.io/xcframework-cli`

## Phases

| Phase | Title | Status | Effort |
|-------|-------|--------|--------|
| [01](./phase-01-jekyll-config.md) | Jekyll Configuration | ✅ Complete | 20 min |
| [02](./phase-02-frontmatter-nav.md) | Frontmatter & Navigation | ✅ Complete | 30 min |
| [03](./phase-03-landing-page.md) | Landing Page (index.md) | ✅ Complete | 15 min |
| [04](./phase-04-github-pages-enable.md) | Enable GitHub Pages | ✅ Complete | 10 min |

## Key Dependencies

- GitHub repo: `phuongddx/xcframework-cli`
- Existing docs: `docs/` (15 markdown files)
- just-the-docs is in GitHub's [safe gems list](https://pages.github.com/versions/) — no CI needed

## Files Modified

**Add:**
- `docs/_config.yml`
- `docs/Gemfile`
- `docs/index.md`

**Update (frontmatter only):**
- `docs/CONFIGURATION.md`
- `docs/ARCHITECTURE.md`
- `docs/ARCHITECTURE_OVERVIEW.md`
- `docs/CONTRIBUTING.md`
- `docs/CHANGELOG.md`
- `docs/system-architecture.md`
- `docs/code-standards.md`
- `docs/codebase-summary.md`
- `docs/project-roadmap.md`
- `docs/project-overview-pdr.md`
- `docs/RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md`

**Exclude (internal planning docs — hidden via _config.yml):**
- `docs/RESOURCE_BUNDLE_IMPLEMENTATION_PLAN.md`
- `docs/RESOURCE_BUNDLE_STRUCTURE_COMPARISON.md`
- `docs/README.md` (replaced by index.md)
- `docs/INDEX.md` (content merged into index.md)
