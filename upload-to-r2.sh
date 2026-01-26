#!/usr/bin/env bash

set -euo pipefail

BUCKET_NAME="${R2_PODCAST_BUCKET}"

# Validate arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file-path>" >&2
    exit 1
fi

FILE_PATH="$1"

# Validate file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found: $FILE_PATH" >&2
    exit 1
fi

# Prepare file metadata
FILE_PATH=$(realpath "$FILE_PATH")
FILE_NAME=$(basename "$FILE_PATH")

# Ensure bucket exists
function ensure_bucket_exists() {
    echo "Checking if bucket exists..." >&2

    if wrangler r2 bucket list 2>/dev/null | grep -q "^name:[[:space:]]*$BUCKET_NAME$"; then
        echo "Bucket exists" >&2
        return 0
    fi

    echo "Bucket does not exist. Creating bucket: $BUCKET_NAME" >&2
    if wrangler r2 bucket create "$BUCKET_NAME" >&2; then
        echo "Bucket created successfully" >&2
    else
        echo "Error: Failed to create bucket" >&2
        exit 1
    fi
}

# Get file size (macOS and Linux compatible)
function get_file_size() {
    stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null
}

# Extract MP3 duration if applicable
function get_mp3_duration() {
    local file_ext="${FILE_NAME##*.}"

    # Check if file is MP3 (case-insensitive)
    if [[ "${file_ext,,}" != "mp3" ]]; then
        echo "null"
        return
    fi

    # Check if ffprobe is available
    if ! command -v ffprobe >/dev/null 2>&1; then
        echo "Warning: ffprobe not found, duration will be null" >&2
        echo "null"
        return
    fi

    # Get duration in seconds
    local duration_seconds
    duration_seconds=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$FILE_PATH" 2>/dev/null || echo "")

    if [ -z "$duration_seconds" ]; then
        echo "null"
        return
    fi

    # Convert to hh:mm:ss format
    local total_seconds=$(printf "%.0f" "$duration_seconds")
    printf "%02d:%02d:%02d" \
        $((total_seconds / 3600)) \
        $(((total_seconds % 3600) / 60)) \
        $((total_seconds % 60))
}

# Upload file to R2
function upload_file() {
    echo "Uploading file to R2..." >&2
    if wrangler r2 object put "$BUCKET_NAME/$FILE_NAME" --file "$FILE_PATH" --remote >&2; then
        echo "Upload successful" >&2
    else
        echo "Error: Failed to upload file" >&2
        exit 1
    fi
}

# Generate public URL
function generate_url() {
    # Try to get custom domain
    local custom_domain
    custom_domain=$(wrangler r2 bucket domain list "$BUCKET_NAME" 2>/dev/null |
                    grep "^domain:" |
                    awk '{print $2}' |
                    head -n 1)

    if [ -n "$custom_domain" ]; then
        echo "https://${custom_domain}/${FILE_NAME}"
        return
    fi

    # Fallback to storage URL
    local account_id
    account_id=$(wrangler whoami 2>/dev/null |
                 grep -E '^│.*│.*│$' |
                 grep -v 'Account Name' |
                 grep -v '─' |
                 awk -F'│' '{print $3}' |
                 tr -d ' ')

    if [ -n "$account_id" ]; then
        echo "https://${account_id}.r2.cloudflarestorage.com/${BUCKET_NAME}/${FILE_NAME}"
    else
        echo "https://<configure-custom-domain>/${FILE_NAME}"
    fi
}

# Output JSON result
function output_json() {
    local url="$1"
    local size="$2"
    local duration="$3"

    # Format duration for JSON (with or without quotes)
    local duration_json
    if [ "$duration" = "null" ]; then
        duration_json="null"
    else
        duration_json="\"$duration\""
    fi

    cat <<EOF
{
  "full_url": "$url",
  "relative_path": "$FILE_NAME",
  "file_size": $size,
  "duration": $duration_json
}
EOF
}

# Main execution
ensure_bucket_exists
FILE_SIZE=$(get_file_size "$FILE_PATH")
DURATION=$(get_mp3_duration)
upload_file
FULL_URL=$(generate_url)
output_json "$FULL_URL" "$FILE_SIZE" "$DURATION"