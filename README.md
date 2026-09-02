# yt_transcript_mcp

A lightweight MCP server that fetches YouTube video transcripts. Built in Swift, runs as a local binary. No Node, no Python, no npx.

## What it does and why I built it

It gives AI assistants two tools: fetch a YouTube video's transcript, and list the caption languages available. I built it because watching video for information is now the slow path. Even at 2x, a 40-minute talk costs 20 minutes; the transcript plus a model that can synthesize it costs moments. I use it daily inside Claude Code to pull technical talks, tutorials, and research videos into text I can actually work with.

## How it was built

One day, March 10, 2026: first commit 11:09 AM, packaged binary 4:06 PM, with more than half of that time spent on review findings, security hardening, and packaging rather than initial code. The work ran as five phases planned as GitHub issues before any code existed. A second Claude Code instance acted as an independent reviewer with fresh context, filing 17 findings as issues against the build (a language-keyed cache bug, SSRF hardening, a fail-fast regex decision) rather than fixing anything silently, and I arbitrated each one. The full narrative, dead ends included, is in [BUILDLOG.md](BUILDLOG.md).

Decisions that were mine, for the record: user-supplied URLs never reach URLSession (fetch URLs are built from the extracted video ID and a hardcoded template), stdout belongs exclusively to JSON-RPC, and the static regex uses try! on purpose so a broken pattern crashes at startup instead of silently failing every lookup.

## Current shortcomings

- The InnerTube androidClientVersion string is maintenance-sensitive. YouTube periodically enforces minimum versions, and when fetching breaks, this is the first thing to update. The tool depends on YouTube internals that can change without notice.
- Requests are unauthenticated, so private videos return "No captions available" even when captions exist. Videos must be public or unlisted.
- The cache is in-memory only and lives for the server process. Restart the server, refetch everything.
- No preference between auto-generated and manually created transcripts. You get what the fallback order gives you (tracked as issue #16).
- macOS 13+ only. No Linux build yet.

## What's next

- Auto-generated vs manual transcript preference (#16)
- Hosting a version online for access away from the desktop
- A Linux build if anyone besides me wants one

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
| `url` | string | Yes | YouTube video URL or video ID |

Both tools accept any standard YouTube URL format (`youtube.com/watch?v=`, `youtu.be/`, `/embed/`, `/shorts/`) or a raw 11-character video ID.

Responses include video metadata (title, channel, duration, description) alongside the transcript or language list.

## Requirements

- macOS 13+
- Swift 6.2+ toolchain (current Xcode)

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

Or build the `.mcpb` bundle with `./scripts/build_mcpb.sh` and install it as a Claude Desktop extension.

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

## Troubleshooting

Enable debug logging with the `YT_TRANSCRIPT_LOG_LEVEL` environment variable:

```bash
YT_TRANSCRIPT_LOG_LEVEL=debug claude mcp add yt_transcript -- /path/to/yt_transcript_mcp
```

Or in Claude Desktop config:

```json
{
  "mcpServers": {
    "yt_transcript": {
      "command": "/path/to/yt_transcript_mcp",
      "env": { "YT_TRANSCRIPT_LOG_LEVEL": "debug" }
    }
  }
}
```

## License

MIT. See [LICENSE](LICENSE).
