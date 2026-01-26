#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./scripts/new-episode.sh episode-slug"
  echo "Example: ./scripts/new-episode.sh my-first-episode"
  exit 1
fi

SLUG="$1"

# Count existing episodes (excluding _index.md)
CONTENT_DIR="content/episodes"
NEXT_NUM=$(find "$CONTENT_DIR" -name "*.md" ! -name "_index.md" 2>/dev/null | wc -l | tr -d ' ')
NEXT_NUM=$((NEXT_NUM + 1))
PADDED=$(printf "%03d" $NEXT_NUM)

FILENAME="${PADDED}-${SLUG}.md"

hugo new "episodes/${FILENAME}" -k episodes

echo "✓ Created: content/episodes/${FILENAME}"
echo "✓ Episode number: ${NEXT_NUM} (${PADDED})"
echo ""
echo "Next steps:"
echo "1. Record audio and export as ${PADDED}-${SLUG}.mp3"
echo "2. Upload to R2: ./upload-to-r2.sh path/to/${PADDED}-${SLUG}.mp3"
echo "3. Copy JSON output values to frontmatter in content/episodes/${FILENAME}"
echo "4. Edit show notes"
echo "5. Set draft: false when ready"
