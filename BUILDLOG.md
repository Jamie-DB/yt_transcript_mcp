# Build Log

One session, one day: March 10, 2026, first commit 11:09 AM, packaged binary 4:06 PM. 20 commits, 1,404 lines across 14 files, 27 GitHub issues opened and 26 closed the same day. Development ran as five planned phases with a second Claude Code instance acting as an independent code reviewer, filing findings as issues against the working instance. The ratio is the point: the working build existed by early afternoon, and more than half the day went to review findings, security hardening, and packaging. Generating the code was the fast part. Verifying it was the job.

**11:09 AM. Plan before code.** Empty Swift Package Manager executable, the official MCP Swift SDK, and GitHub issues #1 through #6 laying out five phases plus an open-questions issue before any real code existed. The phase structure held for the whole build.

**12:06 PM. Phase 1, a server that says hello.** Minimal MCP server over stdio with a dummy tool. The most important decision of the phase was a prohibition: no print() anywhere, ever, because stdout belongs to JSON-RPC and a single stray print corrupts the protocol. All logging goes through swift-log to stderr. That rule is in CLAUDE.md and never got broken.

**12:12 PM. Phase 2, URL parsing with a security rule filed early.** VideoIDExtractor handles every YouTube URL shape (watch, youtu.be, embed, shorts, raw ID) with tests. Review pressure showed up before the network code existed: issue #7 added an SSRF prevention rule to CLAUDE.md ahead of Phase 3, so fetch URLs are always built from a hardcoded template with the extracted video ID, and user-supplied strings never reach URLSession. Issue #8 changed static regex init from try? to try!, the counterintuitive-but-correct choice: a bad pattern should crash at startup, not silently turn every URL into a non-match.

**12:41 PM. Phase 3, the actual fetch.** Transcript fetching via YouTube's InnerTube API with an Android client context. Follow-through on the security posture in the same hour: caption URL domains are validated before fetching (#9, defense in depth), parsing was hardened against malformed responses (#10), and an @unchecked Sendable annotation was challenged and removed rather than papered over (#12).

**12:52 PM. Phase 4, tools wired and tested offline.** Both MCP tools registered and working end to end. Offline unit tests cover caption XML parsing and entity decoding (#11) so the test suite does not depend on YouTube being reachable. Video metadata rides along with every response (#13), and an actor-based in-memory cache eliminates repeat fetches within a session (#15).

**1:28 PM. The review batch lands.** A single cleanup commit closed a stack of reviewer findings: extracted constants, preserved JSON parsing errors instead of swallowing them, removed a dead error case (#19), static regex extraction (#17). The reviewer was a separate Claude Code instance with fresh context running against the same repo, and its findings were filed as issues #7 through #23 rather than applied silently.

**2:12 PM. The bug worth remembering.** Review caught that transcripts were cached by the requested language, not the language actually returned (#20). With fallback behavior, asking for Spanish on a video that only has English would poison the cache with a mislabeled entry. Small fix, real bug, and exactly the kind that ships when nobody is checking.

**2:19 PM to 2:43 PM. Phase 5, polish.** README with build and registration instructions (plus a same-hour correction to it, #21), default log level .info with an environment variable override (#22), and a configured URLSession with 15-second request timeouts instead of .shared (#23).

**3:23 PM to 4:06 PM. Packaging past the finish line.** .mcpb bundle support so the server installs as a Claude Desktop extension (#24), a build script hardened with a CLI guard and project-directory handling (#25, #26), and a spec discovery: the mcpb manifest only accepts name and description per tool, with full input schemas discovered at runtime (#27).

**Since then.** In daily use as a Claude Code MCP server for months (surviving session logs show it summarizing research videos well after the build). One open stretch goal: preferring manual over auto-generated transcripts (#16). One known maintenance point, documented: the InnerTube androidClientVersion string is the thing to update first when fetching breaks. Repo is private pending public release.
