# Tech Stack: Vercel Docs Site

## Decision

**Framework:** Nextra (Next.js + Nextra)
**Hosting:** Vercel
**Styling:** Tailwind CSS (via Nextra)

## Rationale

| Criteria | Nextra | Docusaurus |
|----------|--------|-------------|
| Vercel native | ✅ Zero config | ✅ Works |
| Search | ✅ Pagefind (static) | ✅ Algolia (requires API key) |
| Ruby syntax | ✅ Shiki built-in | ✅ Prism |
| Migration effort | ✅ Low | ✅ Low |
| Bundle size | ✅ Smaller | Larger |

## Migration Plan

1. Move existing docs to `/docs` folder (already done)
2. Create Next.js + Nextra project structure
3. Configure nextra.config.ts for Ruby gem docs
4. Deploy to Vercel

## Existing Content

- ~20 Markdown files in `./docs/`
- Jekyll config already present
- Will migrate after new site is ready
