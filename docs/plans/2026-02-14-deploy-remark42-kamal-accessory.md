---

# Deploy Remark42 as Kamal Accessory + Embed in Hugo Blog

## Overview

Add Remark42 comment system to apmyp.pro blog posts. Remark42 runs as a Kamal accessory on VPS 65.109.160.232, proxied via kamal-proxy at comments.apmyp.pro. Hugo templates get a JS embed widget. DNS already configured.

## Context

- Files involved:
  - `vektorputi.me/config/deploy.yml` - add accessories.remark42 block
  - `vektorputi.me/.kamal/secrets` - add SECRET for Remark42
  - `apmyp.pro__hugo/config.toml` - add [params.remark42] section
  - `apmyp.pro__hugo/themes/default/layouts/partials/post.html` - add embed widget
- Related patterns: deploy.yml has commented-out accessories section (db, redis examples); Hugo config uses TOML with [params.*] sections; kamal-proxy already serves vektorputi.me and apmyp.dev on same VPS
- Dependencies: Docker image `ghcr.io/umputun/remark42:latest` (pulled directly)

## Development Approach

- No tests (infrastructure config + Hugo template)
- Automate all steps: file edits, secret generation, kamal boot, kamal-proxy registration, Hugo commit+push+deploy
- DNS already verified: `comments.apmyp.pro -> 65.109.160.232`

## Implementation Steps

### Task 1: Add Remark42 secret to Kamal secrets

**Repo:** vektorputi.me
**Files:**
- Modify: `.kamal/secrets`

- [x] Generate secret via `openssl rand -hex 32`
- [x] Append `SECRET=<generated_value>` line to `.kamal/secrets`

### Task 2: Add Remark42 accessory to Kamal deploy config

**Repo:** vektorputi.me
**Files:**
- Modify: `config/deploy.yml`

- [x] Append `accessories:` block (replacing the commented-out section) with `remark42:` entry:
  - image: `ghcr.io/umputun/remark42:latest`
  - host: `65.109.160.232`
  - port: `"127.0.0.1:8080:8080"`
  - env clear: REMARK_URL=https://comments.apmyp.pro, SITE=apmyp.pro, AUTH_ANON=true
  - env secret: SECRET
  - volumes: `remark42_data:/srv/var`
  - options: restart: unless-stopped

### Task 3: Commit and boot Remark42 accessory

**Repo:** vektorputi.me

- [x] Commit changes (deploy.yml + secrets)
- [x] Run `kamal accessory boot remark42` from vektorputi.me directory
- [x] Verify container is running via SSH: `docker ps | grep remark42`

### Task 4: Register Remark42 with kamal-proxy

- [x] SSH to server and run: `docker exec kamal-proxy kamal-proxy deploy remark42 --target 172.18.0.4:8080 --host comments.apmyp.pro --tls --health-check-path /ping` (used container IP instead of localhost; added --health-check-path /ping since default /up doesn't exist)
- [x] Verify: `curl https://comments.apmyp.pro/ping` returns pong

### Task 5: Add Remark42 params to Hugo config

**Repo:** apmyp.pro__hugo
**Files:**
- Modify: `config.toml`

- [ ] Add `[params.remark42]` section after `[params.podcast]`:
  - `host = "https://comments.apmyp.pro"`
  - `site_id = "apmyp.pro"`

### Task 6: Add Remark42 embed to post template

**Repo:** apmyp.pro__hugo
**Files:**
- Modify: `themes/default/layouts/partials/post.html`

- [ ] Add comments section after closing `</div>` of `post-container` (line 26), before closing `</div>` of `wrapper` (line 27)
- [ ] Wrap in `{{ if not .Params.disableComments }}`
- [ ] Include `<div id="remark42"></div>`
- [ ] Include `<script>` with `remark_config` object: host and site_id from `.Site.Params.remark42`, locale "ru"
- [ ] Include standard Remark42 embed.es6.mjs script loader

### Task 7: Commit, push, and deploy Hugo site

**Repo:** apmyp.pro__hugo

- [ ] Commit changes (config.toml + post.html)
- [ ] Push to master (triggers Cloudflare Pages auto-deploy)
- [ ] Run `./deploy.sh` to build locally and clear Cloudflare cache

### Task 8: End-to-end verification

- [ ] `curl https://comments.apmyp.pro/ping` returns pong
- [ ] `kamal accessory logs remark42` shows no errors
- [ ] Visit a blog post - Remark42 widget appears below content
- [ ] Test `disableComments: true` in a post front matter hides the widget
