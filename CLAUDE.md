# CLAUDE.md

> **What this file is:** A living context harness. It is loaded at the start of every session and applies to every response unless explicitly overridden in conversation. It is not a static document; it is designed to grow and refine itself through two complementary mechanisms: a real-time self-correcting rules engine that captures corrections as they happen, and an end-of-session review that consolidates and curates what was learned.
>
> **How it works:** During a session, any time the user corrects you, rejects an approach, or states a preference, you immediately append a numbered rule to the "Learned Rules" log at the bottom of this file. At the end of each session, the Self-Evolution Protocol prompts a review: learned rules can be promoted into the curated sections above, stale entries can be flagged, and new context can be added. Over time, this file becomes a rich, personalized context layer that reflects the user's voice, preferences, patterns, and accumulated project knowledge.
>
> **Why it matters:** Without this, every new session starts from zero. With it, each session picks up where the last one left off, and the file gets sharper the more it's used.

---

## Core Rules

> Hard constraints that apply universally. These are non-negotiable unless the user explicitly revokes one in conversation.

- Never use em dashes (---, —). Use commas, periods, semicolons, or parentheses instead.

## Self-Correcting Rules Engine

> This is the real-time capture mechanism. It runs continuously during every session.

### How it works

1. When the user corrects you or you make a mistake, **immediately append a new rule** to the "Learned Rules" section at the bottom of this file.
2. Rules are numbered sequentially and written as clear, imperative instructions.
3. Format: `N. [CATEGORY] Never/Always do X, because Y.`
4. Categories: `[STYLE]`, `[CODE]`, `[ARCH]`, `[TOOL]`, `[PROCESS]`, `[DATA]`, `[UX]`, `[OTHER]`
5. Before starting any task, scan all rules below for relevant constraints.
6. If two rules conflict, the higher-numbered (newer) rule wins.
7. Never delete rules. If a rule becomes obsolete, append a new rule that supersedes it.

### When to add a rule

- User explicitly corrects your output ("no, do it this way")
- User rejects a file, approach, or pattern
- You hit a bug caused by a wrong assumption about this codebase
- User states a preference ("always use X", "never do Y")

### Rule format example

```
14. [CODE] Always use `bun` instead of `npm`, because user preference; bun is installed globally.
15. [STYLE] Never add emojis to commit messages, because project convention.
16. [ARCH] API routes live in `src/server/routes/`, not `src/api/`, because existing codebase pattern.
```

## Self-Evolution Protocol

> This is the reflective review mechanism. It runs once at the close of every session. It complements the real-time rules engine by consolidating, curating, and organizing what was captured.

- At the end of every session, ask: **"Would you like to update CLAUDE.md with any new rules, preferences, or things we learned during this session?"**
- If yes, propose the specific additions or changes (with the target section noted) before writing them.
- During review, consider whether any learned rules should be **promoted** into the curated sections above (e.g., a `[CODE]` rule about naming conventions moves into "Coding Conventions").
- Changes should be written directly into this file so they persist and load automatically in future sessions.
- Keep entries concise. Each rule or note should be a single bullet or short paragraph.
- If a rule becomes outdated or contradicts a newer one, flag it for removal or revision rather than silently ignoring it.

## Project Context

**yt_transcript_mcp** is a Swift 6.0 MCP server that fetches YouTube transcripts for AI assistants. It runs as a local stdio subprocess spawned by Claude Code/Desktop, not as a standalone app or GUI.

- **Type:** Command-line executable (Swift Package Manager), NOT an iOS/macOS app
- **SDK:** Official `modelcontextprotocol/swift-sdk` (v0.11.0+)
- **Platform:** macOS 13+
- **Dependencies:** MCP Swift SDK, swift-log, Foundation (URLSession)
- **Two tools:** `get_youtube_transcript`, `list_transcript_languages`
- **Planning doc:** [Notion project page]([internal planning doc])
- **GitHub Issues #1-#6** track the development phases and open questions

## Writing Style

> Tone, voice, formatting, and language preferences.

## Preferences

- This is a learning project. Prioritize clarity and understanding over cleverness.
- Work in phases (see GitHub Issues). Don't skip ahead or build everything at once.
- Commit at natural checkpoints within each phase.
- No branch workflow; work directly on main.

## Coding Conventions

- **Swift 6.0** with strict concurrency
- **Never use `print()`**. stdout is reserved for JSON-RPC. All logging through `swift-log` to stderr.
- **Tool names must be snake_case** (some MCP clients silently ignore other conventions)
- **All names use underscores**, not hyphens (package, repo, tools, everything)
- Always include input schema on MCP tools, even if simple (some clients won't discover tools without it)
- Return errors as `.init(content: [.text("error message")], isError: true)` rather than throwing
- Always construct fetch URLs from the extracted video ID using a hardcoded template. Never pass user-provided URLs directly to URLSession. The VideoIDExtractor output is the trust boundary.
- Source layout:
  ```
  Sources/
    main.swift              - entry point, server setup, transport start
    TranscriptFetcher.swift - YouTube page fetch, caption URL extraction, XML parsing
    VideoIDExtractor.swift  - URL parsing for all YouTube URL formats
    Tools.swift             - MCP tool definitions and handler registration
  ```

## Do Not

- Do not use `print()` anywhere. It corrupts the JSON-RPC protocol on stdout.
- Do not build this as an app target. It is an executable Swift package.
- Do not use hyphenated names. Project convention is underscores everywhere.
- Do not pass user-supplied URL strings directly to URLSession. Always extract the video ID first and construct URLs from hardcoded templates.

## Things to Remember

- The InnerTube Android client version (`androidClientVersion` in TranscriptFetcher) is the maintenance-sensitive value. YouTube periodically enforces minimum versions. If transcript fetching breaks, update this version first.
- YouTube serves different content without a browser-like User-Agent header. Always set one on URLSession requests.
- To debug: build in Xcode, have Claude spawn the binary, then Debug > Attach to Process in Xcode.
- Registration: `claude mcp add yt_transcript -- /full/path/to/.build/release/yt_transcript_mcp`

---

## Learned Rules

> This is the append-only log. New rules are captured here in real time during sessions. Do not edit above this divider during a session. During end-of-session review, well-established rules may be promoted into the curated sections above.

1. [CODE] Always use underscores, not hyphens, for all naming in this project (repo, package, tools), because user preference to avoid mixed conventions.
