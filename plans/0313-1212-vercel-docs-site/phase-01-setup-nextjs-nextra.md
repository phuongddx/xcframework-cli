# Phase 1: Setup Next.js + Nextra

## Context

Part of plan: `/Users/ddphuong/Projects/xcframework-cli/plans/0313-1212-vercel-docs-site/plan.md`

## Overview

- **Priority:** High
- **Status:** ✅ complete
- **Setup Nextra docs framework from scratch

## Requirements

- Create docs-site directory at project root
- Initialize Next.js 14 with TypeScript + Tailwind
- Install Nextra and Nextra theme docs
- Configure basic project structure

## Implementation Steps

1. Create `docs-site/` directory
2. Initialize Next.js:
   ```bash
   npx create-next-app@latest docs-site --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --no-turbopack
   ```
3. Install Nextra v3 dependencies (latest stable):
   ```bash
   cd docs-site
   npm install nextra@latest nextra-theme-docs@latest react@latest react-dom@latest
   npm install -D @types/react @types/node typescript
   ```
4. Create `.nvmrc` with `20` (Node 20 LTS)
5. Create `.npmrc` with `save-exact=true`
4. Create `docs-site/next.config.mjs`:
   ```javascript
   import nextra from 'nextra'

   const withNextra = nextra({
     theme: 'nextra-theme-docs',
     themeConfig: './nextra.config.ts'
   })

   export default withNextra()
   ```
6. Update `docs-site/package.json` scripts if needed

## File Ownership

- `docs-site/` - ALL files created in this phase

## Success Criteria

- [x] `docs-site/` directory exists at project root
- [x] `npm run dev` starts Next.js server
- [x] Basic page renders at localhost:3000

## Next Steps

Phase 2: Configure Nextra (can run in parallel)
