# Phase 2: Configure Nextra

## Context

Part of plan: `/Users/ddphuong/Projects/xcframework-cli/plans/0313-1212-vercel-docs-site/plan.md`

## Overview

- **Priority:** High
- **Status:** ✅ complete
- Configure Nextra theme, navigation, and syntax highlighting

## Requirements

- Configure nextra.config.ts with theme settings
- Enable Ruby syntax highlighting (built-in Shiki)
- Configure local search
- Configure dark mode and theming

## Implementation Steps

1. Create `docs-site/nextra.config.ts`:
   ```typescript
   import { defineConfig } from 'nextra'

   export default defineConfig({
     title: 'XCFramework CLI',
     description: 'Build XCFrameworks across all Apple platforms',
     project: {
       link: 'https://github.com/phuongddx/xcframework-cli'
     },
     search: {
       provider: 'local'
     },
     sidebar: {
       defaultMenuCollapseLevel: 1,
       toggleButton: true
     },
     navbar: {
       transparent: true,
       links: [
         {
           title: 'GitHub',
           href: 'https://github.com/phuongddx/xcframework-cli'
         }
       ]
     },
     footer: {
       text: 'XCFramework CLI — MIT Licensed'
     },
     darkMode: true,
     primaryHue: 210,
     primarySaturation: 80,
     codeHighlight: true
   })
   ```

2. **Skip custom layout.tsx** - Nextra provides its own. Remove any conflicting app/layout.tsx.

3. Create `docs-site/app/page.mdx` (homepage):
   ```mdx
   # XCFramework CLI

   Build XCFrameworks across all Apple platforms — iOS, macOS, tvOS, watchOS, visionOS, Catalyst.

   ## Features

   - Simple YAML configuration
   - Multi-platform support
   - Automatic dependency management
   - Clean build output
   ```

4. **Verify build works locally** before proceeding:
   ```bash
   cd docs-site && npm run build
   ```

## File Ownership

- `docs-site/nextra.config.ts` - Nextra configuration
- `docs-site/app/page.mdx` - Homepage content

## Success Criteria

- [x] `npm run build` succeeds locally
- [x] Nextra theme renders with custom title
- [x] Local search is functional
- [x] Ruby syntax highlighting works

## Next Steps

Phase 3: Migrate Docs (depends on this phase)
