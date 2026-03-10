# yt_transcript_mcp

A lightweight MCP server that fetches YouTube video transcripts. Built in Swift, runs as a local binary. No Node, no Python, no npx.

## Tools

### `get_youtube_transcript`

Fetches the transcript/captions for a YouTube video. Returns timestamped text by default.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | Yes | YouTube video URL or video ID |
| `language` | string | No | Language code (e.g. `en`, `es`, `fr`). Falls back to the first available track if not found. |
| `include_timestamps` | boolean | No | Include timestamps in output. Defaults to `true`. |

### `list_transcript_languages`

Lists available transcript/caption languages for a YouTube video.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `url` | string | No | YouTube video URL or video ID |

Both tools accept any standard YouTube URL format (`youtube.com/watch?v=`, `youtu.be/`, `/embed/`, `/shorts/`) or a raw 11-character video ID.

Responses include video metadata (title, channel, duration, description) alongside the transcript or language list.

## Requirements

- macOS 13+
- Swift 6.0+ (Xcode 16+ or a matching Swift toolchain)

## Build

```bash
git clone https://github.com/Jamie-DB/yt_transcript_mcp.git
cd yt_transcript_mcp
swift build -c release
```

The binary lands at `.build/release/yt_transcript_mcp`.

## Register

### Claude Code

```bash
claude mcp add yt_transcript -- /full/path/to/.build/release/yt_transcript_mcp
```

### Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "yt_transcript": {
      "command": "/full/path/to/.build/release/yt_transcript_mcp"
    }
  }
}
```

### Cursor

Add to `.cursor/mcp.json` in your project or `~/.cursor/mcp.json` globally:

```json
{
  "mcpServers": {
    "yt_transcript": {
      "command": "/full/path/to/.build/release/yt_transcript_mcp"
    }
  }
}
```

Replace `/full/path/to/` with the actual path to your cloned repo in all examples above.

## Run tests

```bash
swift test
```

Unit tests (URL parsing, XML parsing) run offline. Integration tests fetch from YouTube and require network access.

## How it works

1. Extracts the video ID from whatever URL format is provided
2. Fetches the InnerTube API key from the YouTube video page
3. Calls YouTube's InnerTube API with an Android client context to get caption track metadata
4. Fetches and parses the caption XML for the requested language
5. Returns timestamped transcript text with video metadata

Transcripts are cached in memory for the lifetime of the server process to avoid redundant network calls.

## Maintenance

The InnerTube Android client version (`androidClientVersion` in `TranscriptFetcher.swift`) is the maintenance-sensitive value. YouTube periodically enforces minimum versions. If transcript fetching stops working, update this version string first.
