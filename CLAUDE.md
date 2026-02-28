# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Hugo blog (`apmyp.pro`) with three content sections: posts (blog), books (reading notes), and episodes (podcast). Deployed to Cloudflare Pages via `git push` to `master` (auto-deploy). Comments powered by Remark42 at `comments.apmyp.pro`.

## Commands

```bash
# Local development server with live reload
hugo server

# Production build (outputs to ./public)
hugo --gc --minify

# Build + optional Cloudflare cache purge
./deploy.sh

# Create a new blog post
hugo new posts/my-post-slug.md

# Create a new podcast episode (auto-numbers)
./scripts/new-episode.sh episode-slug

# Upload podcast MP3 to Cloudflare R2 (requires R2_PODCAST_BUCKET env var)
./upload-to-r2.sh path/to/file.mp3
```

## Architecture

**Theme:** Custom theme in `themes/default/`. Compiled CSS/JS live as static files (`static/css/main.min.css`, `static/js/index.min.js`) — there is no build pipeline for the frontend assets.

**Content model:**
- `content/posts/` — blog posts. Front matter: `title`, `date`, `categories`, `description`, `toc` (bool), `disableComments` (bool)
- `content/books/` — book notes. Custom list template at `themes/default/layouts/books/list.html`
- `content/episodes/` — podcast episodes. Front matter adds: `episodeNumber`, `episodeSeason`, `audioUrl`, `duration`, `fileSize`, `description`

**Categories** are defined as a taxonomy in `config.toml` and listed in `data/Categories.json`. Month names in Russian (genitive case) come from `data/Months.toml` — used in all date displays.

**Podcast RSS** is generated as a custom output format `podcast` (renders as `podcast.xml`) in the home page outputs. The feed template lives in the theme.

**Remark42 comments** embed only in `section == "posts"` and only when `disableComments` is not set. Config comes from `[params.remark42]` in `config.toml`.

**Deployment:** `git push master` triggers Cloudflare Pages auto-deploy. `./deploy.sh` is a manual helper that builds locally and purges the Cloudflare cache (requires `CLOUDFLARE_TOKEN` and `CLOUDFLARE_ZONE_ID` env vars).

## Key layout files

- `themes/default/layouts/_default/baseof.html` — base HTML skeleton
- `themes/default/layouts/partials/post.html` — post article with TOC sidebar and Remark42 widget
- `themes/default/layouts/episodes/single.html` — episode page with `<audio>` player
- `themes/default/layouts/index.html` — homepage (latest episode + blog posts)
