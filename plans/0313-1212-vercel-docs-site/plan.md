# Plan: Vercel Docs Site for xcframework-cli

**Created:** 2026-03-13
**Mode:** parallel
**Tech Stack:** Nextra (Next.js 14) + Vercel

## Overview

Create a Vercel-deployable docs site using Nextra framework, migrating existing Markdown docs.

## Phases

| Phase | Status | Ownership |
|-------|--------|-----------|
| 1. Setup Next.js + Nextra | ✅ complete | Phase 1 |
| 2. Configure Nextra | ✅ complete | Phase 2 |
| 3. Migrate Docs | ✅ complete | Phase 3 |
| 4. Vercel Deploy | ✅ complete | Phase 4 |

## Dependency Graph

```
[Phase 1: Setup] ──┬──> [Phase 2: Configure]
                    │
                    └──> [Phase 3: Migrate] ──> [Phase 4: Deploy]
```

Phases 1 → 2 → 3 → 4 (sequential, not parallel - Phase 1 creates config referenced by Phase 2)

## Phase Details

### Phase 1: Setup Next.js + Nextra
**File ownership:** `docs-site/` directory (new)
- Create `docs-site/` directory at root
- Initialize Next.js: `npx create-next-app@latest docs-site --typescript --tailwind --eslint`
- Install Nextra: `npm i nextra nextra-theme-docs`
- Create `docs-site/next.config.mjs` with Nextra config
- Create `docs-site/package.json` scripts

### Phase 2: Configure Nextra
**File ownership:** `docs-site/` directory (continues from Phase 1)
- Create `docs-site/nextra.config.ts`:
  - Theme configuration (sidebar, search, nav)
  - Ruby syntax highlighting (built-in Shiki)
  - Dark mode support
- Create `docs-site/app/layout.tsx` with Nextra provider
- Create `docs-site/app/page.mdx` with homepage
- Create `docs-site/app/docs/_meta.json` for navigation structure

### Phase 3: Migrate Docs
**File ownership:** `docs-site/app/docs/` + `docs/` updates
- Copy existing docs from `./docs/` to `docs-site/app/docs/`
- Update frontmatter if needed (Nextra format)
- Create `docs-site/public/` for assets
- Keep existing `./docs/` for GitHub Pages fallback

### Phase 4: Vercel Deploy
**File ownership:** Root level files
- Create `vercel.json` for build config
- Add deployment instructions to README
- Create `.vercelignore` if needed

## Execution Strategy

**Sequential:** Phase 1 → Phase 2 → Phase 3 → Phase 4 (each phase depends on previous)

## File Ownership Matrix

| File/Dir | Owner Phase |
|----------|-------------|
| docs-site/ | Phase 1-2 |
| docs-site/app/docs/ | Phase 3 |
| docs-site/public/ | Phase 3 |
| vercel.json | Phase 4 |
| README.md (update) | Phase 4 |

## Risks

1. **Migration effort** - Existing docs may need frontmatter updates
2. **Search** - Pagefind requires postbuild script
3. **Vercel config** - May need adjustment for static output

## Validation Log

| # | Question | Answer |
|---|----------|--------|
| 1 | Docs hosting strategy | Replace GitHub Pages (migrate fully to Vercel) |
| 2 | Deployment method | GitHub Integration (auto-deploy on push) |
| 3 | Nextra version | Nextra v3 (latest stable) |

## Success Criteria

- [x] Nextra site runs locally with `npm run dev`
- [x] All existing docs accessible
- [x] Ruby syntax highlighting works
- [x] Search functional
- [x] Deployed to Vercel
- [ ] Custom domain (optional)

## Red Team Review

### Session — 2026-03-13
**Findings:** 19 (12 accepted, 7 rejected)
**Severity breakdown:** 4 Critical, 8 High, 7 Medium

| # | Finding | Severity | Disposition | Applied To |
|---|---------|----------|-------------|------------|
| 1 | Layout.tsx is wrong - Nextra provides its own | Critical | Accept | Phase 2 |
| 2 | False parallel execution claim | Critical | Accept | plan.md |
| 3 | _meta.json mismatch between phases | Critical | Accept | Phase 2-3 |
| 4 | No build verification before deploy | Critical | Accept | Phase 4 |
| 5 | Missing TypeScript types | High | Accept | Phase 1 |
| 6 | Ruby syntax not enabled | High | Accept | Phase 2 |
| 7 | Search not configured | High | Accept | Phase 2 |
| 8 | Unpinned dependencies | High | Accept | Phase 1 |
| 9 | No NODE_VERSION specification | High | Accept | Phase 4 |
| 10 | Frontmatter migration hand-waved | High | Accept | Phase 3 |
| 11 | No rollback plan | Medium | Accept | plan.md |
| 12 | GitHub Pages conflict | Medium | Accept | plan.md |
