#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="$PROJECT_DIR/.build/mcpb_staging"
OUTPUT_FILE="$PROJECT_DIR/.build/yt_transcript_mcp.mcpb"

echo "==> Building release binary..."
swift build -c release

echo "==> Preparing mcpb bundle..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/server"

cp "$PROJECT_DIR/.build/release/yt_transcript_mcp" "$BUNDLE_DIR/server/"
cp "$PROJECT_DIR/manifest.json" "$BUNDLE_DIR/"

echo "==> Packing mcpb bundle..."
mcpb pack "$BUNDLE_DIR" "$OUTPUT_FILE"

echo "==> Done!"
echo "   Binary:  $PROJECT_DIR/.build/release/yt_transcript_mcp"
echo "   Bundle:  $OUTPUT_FILE"
