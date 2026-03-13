# Nextra Framework Research Report

## 1. Installation & Setup (Next.js 14+)

**Dependencies:**
```bash
npm i next react react-dom nextra nextra-theme-docs
# or: pnpm add / yarn add / bun add
```

**package.json scripts:**
```json
"scripts": {
  "dev": "next",
  "build": "next build",
  "start": "next start"
}
```

**next.config.mjs:**
```javascript
import nextra from 'nextra'

const withNextra = nextra({
  // Nextra options
})

export default withNextra({
  // Next.js options
})
```

**Root layout (app/layout.jsx):** Import from `nextra-theme-docs` - `Layout`, `Navbar`, `Footer`, `getPageMap`.

---

## 2. nextra.config.ts Options

Key options passed to `nextra()`:
- `search: false` - disable search
- `search: { codeblocks: false }` - disable code block indexing
- `themeConfig: { ... }` - theme options

Theme options include: `breadcrumb`, `collapsed`, `copyPage`, `footer`, `layout`, `navbar`, `pagination`, `sidebar`, `timestamp`, `toc`, `typesetting`.

---

## 3. Ruby Syntax Highlighting

Nextra uses **Shiki** built-in for syntax highlighting. Ruby is supported out of the box - no extra config needed. Code blocks use:
```ruby
# code fence with ```ruby
def hello
  puts "world"
end
```

For enhanced styling, add `rehype-pretty-code` plugin in next.config.mjs.

---

## 4. Search Configuration (Pagefind)

**Install:** `npm i -D pagefind`

**Add postbuild script:**
```json
"postbuild": "pagefind --site .next/server/app --output-path public/_pagefind"
```

**Ignore:** Add `_pagefind/` to `.gitignore`. Search enabled by default.

---

## 5. Sidebar Navigation

Use `_meta.json` files in each directory:
```json
{
  "folder-title": "Display Title",
  "-": { "type": "separator", "title": "Section Title" }
}
```

Page options: `type: 'page'` (navbar), `display: 'hidden'` (exclude from sidebar).

---

## 6. MDX Support & Frontmatter

MDX enabled by default. Frontmatter in .mdx files:
```yaml
---
title: Page Title
description: Meta description
---
```

Built-in components: `Callout`, `Cards`, `Tabs`, `Steps`, `FileTree`.

---

## 7. Custom Theming

**CSS Variables (light/dark):**
```css
:root {
  --nextra-primary-hue: 212deg;
  --nextra-primary-saturation: 100%;
  --nextra-primary-lightness: 45%;
  --nextra-bg: 250,250,250;
  --nextra-content-width: 90rem;
}
.dark { /* dark mode vars */ }
```

Import custom CSS in layout.jsx. Supports `.css`, `.module.css`, `.scss`.

---

## Unresolved Questions

1. How to configure multiple language versions (i18n)?
2. What's the exact rehype-pretty-code integration for custom line highlighting?
