# Documentation Site Solutions for Vercel Deployment

**Date:** 2026-03-13
**Researcher:** researcher
**Context:** Migrating from Jekyll (GitHub Pages) to Vercel-native solution

## Current Setup
- Jekyll with just-the-docs theme on GitHub Pages
- 15 Markdown files in `./docs`
- Features: search, dark mode, nav, callouts, syntax highlighting

---

## Options Analysis

### 1. Nextra (Next.js)
**Vercel complexity:** Low (native Next.js support)

| Pros | Cons |
|------|------|
| Zero-config search (Pagefind) | Tightly coupled to Next.js |
| Shiki syntax highlighting (Ruby support) | Requires React knowledge |
| MDX support, dark mode, i18n | Less flexible than standalone MDX |
| Auto image/link optimization | |
| High performance (ISR, code splitting) | |

**Setup:** `npx create-nextra@latest` → deploy to Vercel

---

### 2. Docusaurus
**Vercel complexity:** Low (one-click or CLI)

| Pros | Cons |
|------|------|
| Specialized for docs (versioning, i18n) | React-based (learning curve) |
| Mature, strong community | Heavier than alternatives |
| Built-in search, SEO | Modern browser only |
| Plugin architecture | |
| Little to learn, intuitive structure | |

**Setup:** `npx create-docusaurus@latest` → Vercel import

---

### 3. Starlight (Astro)
**Vercel complexity:** Low (Astro adapter)

| Pros | Cons |
|------|------|
| All-in-one docs features | Tied to Astro ecosystem |
| Fast performance (Astro) | Less mature than Docusaurus |
| MDX, Markdoc support | |
| Framework-agnostic integrations | |
| Built-in search, dark mode, i18n, SEO | |

**Setup:** `npm create astro@latest -- --template starlight` → Vercel adapter

---

### 4. Mintlify
**Vercel complexity:** Low (quick deploy)

| Pros | Cons |
|------|------|
| AI-native, modern UI | Limited self-hosted options |
| Ready-to-use components | Cloud-centric |
| Quickstart deploy | Less customization |
| Web editor for non-devs | |

**Setup:** `mintlify start` → Vercel deployment

---

## Migration Effort Comparison

| Factor | Nextra | Docusaurus | Starlight | Mintlify |
|--------|--------|------------|-----------|----------|
| MDX support | Native | Native | Native | Limited |
| Syntax highlighting | Shiki | Prism | Shiki | Built-in |
| Frontmatter needed | Optional | Optional | Optional | Required |
| Config format | JS/TS | JS/TS | Astro config | JSON/YAML |
| Docs folder structure | `/pages` or `/app` | `/docs` | `/src/content/docs` | `/docs` |
| **Migration complexity** | Medium | Low | Medium | Medium |

---

## Recommendation

**Winner: Docusaurus or Nextra**

- **Best overall:** Docusaurus - mature, docs-specific features (versioning), lowest learning curve, easiest migration
- **Best performance:** Starlight - fastest (Astro), excellent if you might use Astro later
- **Best DX:** Nextra - zero-config search, modern Next.js features

**For this project (Ruby gem docs):**
- Nextra or Docusaurus best - both handle Ruby syntax highlighting well
- Migration: 1-2 hours (move files, adjust frontmatter, deploy)

---

## Setup Time Estimates

| Task | Nextra | Docusaurus | Starlight | Mintlify |
|------|--------|------------|-----------|----------|
| Initial setup | 30 min | 30 min | 30 min | 20 min |
| Migrate 15 MD files | 30 min | 30 min | 30 min | 30 min |
| Configure theme/nav | 30 min | 30 min | 20 min | 20 min |
| Vercel deploy | 10 min | 10 min | 10 min | 10 min |
| **Total** | ~1.5 hrs | ~1.5 hrs | ~1.3 hrs | ~1.2 hrs |

---

## Action Items
1. Test Nextra and Docusaurus locally with sample docs
2. Verify Ruby syntax highlighting quality
3. Deploy to Vercel preview for evaluation
4. Choose based on UI preference and future needs

---

**Unresolved Questions:**
- Does Mintlify support self-hosted deployment without cloud?
- How does Nextra's Pagefind perform with 50+ pages?
