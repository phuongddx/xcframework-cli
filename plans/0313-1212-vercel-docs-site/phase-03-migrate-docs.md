# Phase 3: Migrate Docs

## Context

Part of plan: `/Users/ddphuong/Projects/xcframework-cli/plans/0313-1212-vercel-docs-site/plan.md`

## Overview

- **Priority:** High
- **Status:** ✅ complete
- Migrate existing Markdown docs to Nextra format

## Requirements

- Copy existing docs from `./docs/` to `docs-site/app/docs/`
- Update frontmatter for Nextra compatibility
- **Remove GitHub Pages** - After Vercel deployment succeeds, remove `./docs/` Jekyll setup:
  - Delete `.github/workflows/pages.yml` (if exists)
  - Delete `docs/_config.yml`, `docs/Gemfile`, `docs/Gemfile.lock`
- Create proper navigation structure

## Implementation Steps

1. Create `docs-site/app/docs/` directory
2. Copy key docs (filtering implementation plans):
   - `docs/index.md` → `docs-site/app/docs/index.md`
   - `docs/README.md` → `docs-site/app/docs/getting-started.md`
   - `docs/CONFIGURATION.md` → `docs-site/app/docs/configuration.md`
   - `docs/ARCHITECTURE.md` → `docs-site/app/docs/architecture.md`
   - `docs/CONTRIBUTING.md` → `docs-site/app/docs/contributing.md`
   - `docs/CHANGELOG.md` → `docs-site/app/docs/changelog.md`
   - `docs/code-standards.md` → `docs-site/app/docs/code-standards.md`
   - `docs/codebase-summary.md` → `docs-site/app/docs/codebase-summary.md`
3. Skip implementation-specific files:
   - `RESOURCE_BUNDLE_IMPLEMENTATION_PLAN.md`
   - `RESOURCE_BUNDLE_STRUCTURE_COMPARISON.md`
   - `RESOURCE_BUNDLE_IMPLEMENTATION_COMPLETE.md`
   - `project-overview-pdr.md`
   - `project-roadmap.md`
   - `system-architecture.md`
   - `ARCHITECTURE_OVERVIEW.md`
4. Add/update frontmatter in each file:
   ```yaml
   ---
   title: Page Title
   ---
   ```
5. Create `docs-site/public/` for any assets
6. Create `docs-site/app/docs/_meta.json` with sidebar structure matching migrated docs:
   ```json
   {
     "-- Getting Started": {
       "title": "Getting Started",
       "type": "separator"
     },
     "index": "Introduction",
     "getting-started": "Getting Started",
     "configuration": "Configuration",
     "-- Reference": {
       "title": "Reference",
       "type": "separator"
     },
     "architecture": "Architecture",
     "contributing": "Contributing",
     "changelog": "Changelog",
     "code-standards": "Code Standards",
     "codebase-summary": "Codebase Summary"
   }
   ```
7. Add frontmatter to each doc file:
   ```yaml
   ---
   title: Page Title
   ---
   ```

## File Ownership

- `docs-site/app/docs/` - migrated doc files
- `docs-site/public/` - assets

## Success Criteria

- [x] All relevant docs accessible via sidebar
- [x] No broken links
- [x] Original `./docs/` preserved

## Next Steps

Phase 4: Vercel Deploy (depends on migrated docs)
