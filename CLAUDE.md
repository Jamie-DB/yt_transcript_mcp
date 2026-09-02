# CLAUDE.md

> Living context file. Loaded every session. Grows via real-time rule capture and end-of-session review.

---

## Core Rules

- Never use em dashes (---, —). Use commas, periods, semicolons, or parentheses instead.

## Project Context

**yt_transcript_mcp** is a Swift 6.0 MCP server that fetches YouTube transcripts for AI assistants. It runs as a local stdio subprocess spawned by Claude Code/Desktop, not as a standalone app or GUI.

- **SDK:** Official `modelcontextprotocol/swift-sdk` (v0.11.0+)
- **Platform:** macOS 13+, Swift Package Manager executable
- **Dependencies:** MCP Swift SDK, swift-log, Foundation (URLSession)
- **Two tools:** `get_youtube_transcript`, `list_transcript_languages`
- **Planning history:** GitHub issues #1-#6 (phases and open questions); narrative in BUILDLOG.md
- **GitHub Issues #1-#6** track development phases; **#7-#23** track code review findings
- **Packaging:** Supports `.mcpb` bundle. Run `./scripts/build_mcpb.sh` to build.
- **Status:** All phases (#1-#5) complete. Only stretch goals remain (#16).
- Source layout:
  ```
  Sources/
    main.swift              - entry point, server setup, transport start
    TranscriptFetcher.swift - InnerTube API fetch, caption URL extraction, XML parsing
    TranscriptCache.swift   - actor-based in-memory cache (lives for session duration)
    VideoIDExtractor.swift  - URL parsing for all YouTube URL formats
    Tools.swift             - MCP tool definitions and handler registration
  scripts/
    build_mcpb.sh           - builds release binary + .mcpb bundle
  manifest.json             - mcpb v0.3 manifest for Claude Desktop extension
  ```

## Writing Style

## Preferences

- This is a learning project. Prioritize clarity and understanding over cleverness.
- Code review workflow: a separate Claude Code instance runs `/reviewer` from this directory. Findings are filed as GitHub issues.

## Coding Conventions

- **Swift 6.0** with strict concurrency
- **Never use `print()`**. stdout is reserved for JSON-RPC. All logging through `swift-log` to stderr.
- **Tool names must be snake_case** (some MCP clients silently ignore other conventions)
- **All names use underscores**, not hyphens (package, repo, tools, everything)
- Always include input schema on MCP tools, even if simple
- Return errors as `.init(content: [.text("error message")], isError: true)` rather than throwing
- Construct fetch URLs from extracted video ID using a hardcoded template. Never pass user-provided URLs directly to URLSession.

## Do Not

- Do not use `print()` anywhere. It corrupts the JSON-RPC protocol on stdout.
- Do not build this as an app target. It is an executable Swift package.
- Do not use hyphenated names. Project convention is underscores everywhere.
- Do not pass user-supplied URL strings directly to URLSession.

## Things to Remember

- The InnerTube `androidClientVersion` in TranscriptFetcher is maintenance-sensitive. If fetching breaks, update this version first.
- YouTube serves different content without a browser-like User-Agent header. Always set one.
- Default log level is `.info`. Set `YT_TRANSCRIPT_LOG_LEVEL=debug` for verbose output.
- URLSession uses a configured session with 15s request / 30s resource timeouts (not `.shared`).
- To debug: build in Xcode, have Claude spawn the binary, then Debug > Attach to Process.
- Registration: `claude mcp add yt_transcript -- /full/path/to/.build/release/yt_transcript_mcp`
- The mcpb manifest spec only allows `name` and `description` in the `tools` array. Full input schemas are discovered at runtime via `tools/list`.

---

## Rules Engine

When the user corrects you, rejects an approach, or states a preference, **immediately append a numbered rule** below.

- Format: `N. [CATEGORY] Never/Always do X, because Y.`
- Categories: `[STYLE]`, `[CODE]`, `[ARCH]`, `[TOOL]`, `[PROCESS]`, `[DATA]`, `[UX]`, `[OTHER]`
- Scan rules before starting any task. Newer rules (higher numbers) win conflicts.
- Never delete rules; supersede with a new one if needed.

At end of session, ask: **"Would you like to update CLAUDE.md?"** Promote stable rules into sections above. Keep entries concise.

## Learned Rules

1. [CODE] Always use underscores, not hyphens, for all naming in this project (repo, package, tools), because user preference to avoid mixed conventions.
2. [TOOL] Private YouTube videos return "No captions available" even when captions exist, because the tool makes unauthenticated requests via InnerTube. Videos must be Unlisted or Public for transcript fetching to work.
