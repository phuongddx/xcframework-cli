# Phase 04 — Enable GitHub Pages

**Status:** ✅ Complete
**Effort:** ~10 min

## Overview

Enable GitHub Pages in the repository settings and verify the site builds correctly.

## Steps

### 1. Enable GitHub Pages (UI)

1. Go to `https://github.com/phuongddx/xcframework-cli/settings/pages`
2. Under **Source**: select `Deploy from a branch`
3. Branch: `main` | Folder: `/docs`
4. Click **Save**

GitHub will trigger an automatic Jekyll build. First build takes ~1–2 min.

### 2. Verify Build (CLI)

```bash
# Check Pages deployment status
gh api repos/phuongddx/xcframework-cli/pages

# Watch Actions for Pages build
gh run list --workflow pages-build-deployment
```

### 3. Confirm Live URL

Site will be live at: `https://phuongddx.github.io/xcframework-cli`

### 4. Update README badge (optional)

Add docs badge to root `README.md`:
```markdown
[![Docs](https://img.shields.io/badge/docs-github%20pages-blue)](https://phuongddx.github.io/xcframework-cli)
```

## Todo

- [x] Enable GitHub Pages in repo settings (main / /docs)
- [x] Confirm build succeeds in Actions tab
- [x] Verify live URL loads correctly
- [x] Add docs badge to README.md (optional)

## Verification Checklist

- [x] Home page loads with correct title and navigation
- [x] Sidebar shows all 8 nav items in correct order
- [x] Code blocks render with syntax highlighting
- [x] Search works (type a keyword)
- [x] `just-the-docs` dark theme applied
- [x] No 404 on internal links
