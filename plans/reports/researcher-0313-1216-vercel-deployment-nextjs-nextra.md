# Vercel Deployment for Next.js/Nextra Documentation Sites

## 1. Vercel CLI Deployment

```bash
# Install
npm i -g vercel   # or: bun i -g vercel

# Initial deployment (links to Vercel project)
vercel

# Production deployment
vercel --prod
```

Creates `.vercel/` directory with Project/Org IDs. Use `--prod` for production.

## 2. Dashboard Deployment from GitHub

1. Go to [vercel.com/new](https://vercel.com/new)
2. Import GitHub repository
3. Vercel auto-detects Next.js framework
4. Configure build settings or use defaults

**Auto-deploy**: Every push to any branch creates Preview deployment. Push to main (production branch) triggers Production deployment.

## 3. Environment Variables

- **Dashboard**: Project Settings → Environment Variables
- **Scope**: Production, Preview, Development (per-environment)
- **CLI**: `vercel env add` / `vercel env pull`
- **System vars**: `VERCEL`, `VERCEL_ENV`, `VERCEL_URL`, `VERCEL_GIT_COMMIT_SHA`, etc.
- **Limit**: 64KB total per deployment

## 4. Custom Domain Configuration

1. Project → Settings → Domains
2. Add domain (supports wildcards `*.example.com`)
3. Configure DNS at registrar:
   - **Apex domain**: A record
   - **Subdomain**: CNAME record (unique per project)
   - Or use Vercel Nameservers

## 5. Build Settings

| Setting | Value for Next.js/Nextra |
|---------|--------------------------|
| Framework Preset | Next.js (auto-detected) |
| Build Command | `next build` (auto) |
| Output Directory | `.next` (auto) |
| Install Command | `npm install` (auto) |
| Root Directory | Set if docs in subdirectory (e.g., `docs/`) |

For Nextra (static): Framework Preset → "Other", Output → `/_site` or leave empty.

## 6. GitHub Actions Integration

```yaml
# .github/workflows/vercel.yml
name: Vercel Production
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm i -g vercel@latest
      - run: vercel pull --yes --environment=preview --token=${{ secrets.VERCEL_TOKEN }}
      - run: vercel build --prod --token=${{ secrets.VERCEL_TOKEN }}
      - run: vercel deploy --prebuilt --prod --token=${{ secrets.VERCEL_TOKEN }}
```

**Required**: Add `VERCEL_TOKEN` secret in GitHub repo settings.

## 7. CI/CD Triggers

| Trigger | Action |
|---------|--------|
| Push to main | Production deploy |
| Push to branch | Preview deploy |
| PR opened/updated | Preview deploy + comment |
| `repository_dispatch` event | Custom trigger |

Use `vercel.json` for per-deployment overrides (framework, buildCommand, outputDirectory).

---

**Unresolved Questions:**
- What specific Nextra output directory should be used for static export?
- Is there a need for `NEXT_PUBLIC_` prefix for client-side env vars?
