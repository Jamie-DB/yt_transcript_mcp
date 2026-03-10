import MCP
import Logging

private let toolsLogger = Logger(label: "yt_transcript_mcp.tools")
private let cache = TranscriptCache()

func registerTools(on server: Server) async {
    // List available tools
    await server.withMethodHandler(ListTools.self) { _ in
        ListTools.Result(tools: [
            Tool(
                name: "get_youtube_transcript",
                description: "Fetches the transcript/captions for a YouTube video. Returns timestamped text by default.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "url": .object([
                            "type": .string("string"),
                            "description": .string("YouTube video URL or video ID")
                        ]),
                        "language": .object([
                            "type": .string("string"),
                            "description": .string("Language code (e.g. 'en', 'es', 'fr'). Defaults to first available track, usually 'en'.")
                        ]),
                        "include_timestamps": .object([
                            "type": .string("boolean"),
                            "description": .string("Whether to include timestamps in the output. Defaults to true.")
                        ])
                    ]),
                    "required": .array([.string("url")])
                ])
            ),
            Tool(
                name: "list_transcript_languages",
                description: "Lists available transcript/caption languages for a YouTube video.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "url": .object([
                            "type": .string("string"),
                            "description": .string("YouTube video URL or video ID")
                        ])
                    ]),
                    "required": .array([.string("url")])
                ])
            ),
        ])
    }

    // Handle tool calls
    await server.withMethodHandler(CallTool.self) { params in
        switch params.name {
        case "get_youtube_transcript":
            return await handleGetTranscript(params)
        case "list_transcript_languages":
            return await handleListLanguages(params)
        default:
            return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
        }
    }
}

// MARK: - Tool Handlers

private func handleGetTranscript(_ params: CallTool.Parameters) async -> CallTool.Result {
    guard let urlInput = params.arguments?["url"]?.stringValue else {
        return .init(content: [.text("Missing required parameter: url")], isError: true)
    }

    let language = params.arguments?["language"]?.stringValue
    let includeTimestamps = params.arguments?["include_timestamps"]?.boolValue ?? true

    // Extract video ID (trust boundary)
    let videoID: String
    do {
        videoID = try VideoIDExtractor.extractVideoID(from: urlInput)
    } catch {
        return .init(content: [.text("\(error)")], isError: true)
    }

    // Check cache first
    if let cached = await cache.getTranscript(videoID: videoID, language: language) {
        toolsLogger.info("Serving cached transcript for \(videoID)")
        return formatTranscriptResult(cached, includeTimestamps: includeTimestamps)
    }

    toolsLogger.info("Fetching transcript for \(videoID), language: \(language ?? "default")")

    // Fetch transcript
    let result: TranscriptResult
    do {
        result = try await TranscriptFetcher.fetchTranscript(videoID: videoID, languageCode: language)
    } catch {
        return .init(content: [.text("\(error)")], isError: true)
    }

    // Cache the result
    await cache.storeTranscript(result, videoID: videoID, language: language)

    return formatTranscriptResult(result, includeTimestamps: includeTimestamps)
}

private func handleListLanguages(_ params: CallTool.Parameters) async -> CallTool.Result {
    guard let urlInput = params.arguments?["url"]?.stringValue else {
        return .init(content: [.text("Missing required parameter: url")], isError: true)
    }

    // Extract video ID (trust boundary)
    let videoID: String
    do {
        videoID = try VideoIDExtractor.extractVideoID(from: urlInput)
    } catch {
        return .init(content: [.text("\(error)")], isError: true)
    }

    // Check cache first
    if let cached = await cache.getCaptionTracks(videoID: videoID) {
        toolsLogger.info("Serving cached caption tracks for \(videoID)")
        return formatCaptionTrackResult(cached)
    }

    toolsLogger.info("Listing languages for \(videoID)")

    // Fetch caption tracks
    let result: CaptionTrackResult
    do {
        result = try await TranscriptFetcher.fetchCaptionTracks(videoID: videoID)
    } catch {
        return .init(content: [.text("\(error)")], isError: true)
    }

    // Cache the result
    await cache.storeCaptionTracks(result, videoID: videoID)

    return formatCaptionTrackResult(result)
}

// MARK: - Formatting

private func formatTranscriptResult(
    _ result: TranscriptResult,
    includeTimestamps: Bool
) -> CallTool.Result {
    let meta = result.metadata
    var header = "Title: \(meta.title)\n"
    header += "Channel: \(meta.channel)\n"
    header += "Duration: \(meta.formattedDuration)\n"
    if !meta.description.isEmpty {
        let desc = meta.description.count > 300
            ? String(meta.description.prefix(300)) + "..."
            : meta.description
        header += "Description: \(desc)\n"
    }
    header += "\n---\n\n"

    let body: String
    if includeTimestamps {
        body = result.entries.map { entry in
            let minutes = Int(entry.start) / 60
            let seconds = Int(entry.start) % 60
            return "[\(minutes):\(String(format: "%02d", seconds))] \(entry.text)"
        }.joined(separator: "\n")
    } else {
        body = result.entries.map(\.text).joined(separator: " ")
    }

    return .init(content: [.text(header + body)])
}

private func formatCaptionTrackResult(_ result: CaptionTrackResult) -> CallTool.Result {
    if result.tracks.isEmpty {
        return .init(content: [.text("No captions available")], isError: true)
    }

    let meta = result.metadata
    var header = "Title: \(meta.title)\n"
    header += "Channel: \(meta.channel)\n"
    header += "Duration: \(meta.formattedDuration)\n"
    header += "Available languages: \(result.tracks.count)\n"
    header += "\n---\n\n"

    let listing = result.tracks.map { track in
        let type = track.isAutoGenerated ? "(auto-generated)" : "(manual)"
        return "- \(track.languageCode): \(track.languageName) \(type)"
    }.joined(separator: "\n")

    return .init(content: [.text(header + listing)])
}
