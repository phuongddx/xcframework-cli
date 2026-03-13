# Phase 4: Vercel Deploy

## Context

Part of plan: `/Users/ddphuong/Projects/xcframework-cli/plans/0313-1212-vercel-docs-site/plan.md`

## Overview

- **Priority:** High
- **Status:** ✅ complete
- Deploy the docs site to Vercel

## Requirements

- Configure Vercel build settings
- Deploy to Vercel
- Update README with deployment instructions

## Implementation Steps

1. Create `docs-site/vercel.json`:
   ```json
   {
     "buildCommand": "npm run build",
     "outputDirectory": ".next",
     "framework": "nextjs",
     "nodeVersion": "20"
   }
   ```

2. **Verify build works locally first**:
   ```bash
   cd docs-site && npm run build
   ```

2. Create `.vercelignore` in docs-site (if needed):
   ```
   node_modules
   .git
   README.md
   ```

3. Deploy via GitHub Integration:
   - Push `docs-site/` to GitHub (create `docs-site` branch or add to main)
   - Go to Vercel dashboard → Add New → Project
   - Import from GitHub, select the repository
   - Configure: Framework Preset = Next.js, Output Directory = `.next`
   - Deploy on push (automatic)

4. After successful Vercel deployment, disable GitHub Pages:
   - Go to repo Settings → Pages
   - Disable GitHub Pages

4. Add deployment section to main README.md:
   ```markdown
   ## Documentation Site

   The docs are deployed to Vercel: https://xcframework-cli.vercel.app

   ### Local Development

   ```bash
   cd docs-site
   npm install
   npm run dev
   ```

   ### Deployment

   Deployments happen automatically on push to main branch.
   ```

## File Ownership

- `docs-site/vercel.json` - new file
- `docs-site/.vercelignore` - new file (if needed)
- `README.md` - update

## Success Criteria

- [x] `npm run build` succeeds locally
- [x] Site deployed to Vercel
- [ ] Custom domain configured (optional)
- [x] README updated with instructions
