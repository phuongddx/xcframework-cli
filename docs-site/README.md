# XCFramework CLI Documentation Site

This is the documentation site for XCFramework CLI, built with Next.js and Nextra.

## Setup

### Prerequisites

- Node.js 20.17.0 or later (see `.nvmrc`)
- npm or yarn

### Installation

```bash
npm install
```

### Development

Start the development server:

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to view the site.

### Build

Build for production:

```bash
npm run build
```

Start the production server:

```bash
npm start
```

### Linting

Run ESLint:

```bash
npm run lint
```

## Tech Stack

- **Framework**: Next.js 14.2.28
- **Documentation Theme**: Nextra 2.13.4
- **Language**: TypeScript 5.5.4
- **Styling**: Tailwind CSS 3.4.11
- **Linting**: ESLint 8.57.1

## Project Structure

```
docs-site/
├── pages/              # Documentation pages (MDX/MD files)
│   ├── _app.tsx       # Custom App component
│   ├── _meta.json     # Navigation configuration
│   └── index.md       # Homepage
├── styles/            # Global styles
│   └── globals.css    # Tailwind imports
├── theme.config.jsx   # Nextra theme configuration
├── next.config.mjs    # Next.js configuration with Nextra
├── tsconfig.json      # TypeScript configuration
└── tailwind.config.ts # Tailwind configuration
```

## Adding Documentation

1. Create a new `.md` or `.mdx` file in the `pages/` directory
2. Add the page to `pages/_meta.json` for navigation
3. Write your documentation using Markdown or MDX

## Deployment

The site is configured for deployment on Vercel. See the main project's deployment documentation for details.

## Resources

- [Nextra Documentation](https://nextra.site/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
