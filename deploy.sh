#!/bin/bash
set -e

echo "🧹 Cleaning .DS_Store files..."
find . -name '.DS_Store' -delete

echo "🏗️  Building Hugo site..."
hugo --gc --minify

echo "✅ Build complete! Output in ./public"

# Cloudflare cache clear (optional)
if [ -n "$CLOUDFLARE_TOKEN" ] && [ -n "$CLOUDFLARE_ZONE_ID" ]; then
    echo "🌩️  Clearing Cloudflare cache..."
    curl -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
        -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{"purge_everything":true}'
    echo ""
    echo "✅ Cloudflare cache cleared"
else
    echo "⚠️  Skipping Cloudflare cache clear (CLOUDFLARE_TOKEN or CLOUDFLARE_ZONE_ID not set)"
fi

echo ""
echo "✨ Deploy complete!"
echo "📁 Deploy the ./public directory to your hosting provider"
