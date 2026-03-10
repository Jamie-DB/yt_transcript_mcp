import MCP
import Logging

private let toolsLogger = Logger(label: "yt_transcript_mcp.tools")

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

    toolsLogger.info("Fetching transcript for \(videoID), language: \(language ?? "default")")

    // Fetch transcript
    let entries: [TranscriptEntry]
    do {
        entries = try await TranscriptFetcher.fetchTranscript(videoID: videoID, languageCode: language)
    } catch {
        return .init(content: [.text("\(error)")], isError: true)
    }

    // Format output
    let header = "Video ID: \(videoID) | Entries: \(entries.count)\n---\n"
    let body: String

    if includeTimestamps {
        body = entries.map { entry in
            let minutes = Int(entry.start) / 60
            let seconds = Int(entry.start) % 60
            return "[\(minutes):\(String(format: "%02d", seconds))] \(entry.text)"
        }.joined(separator: "\n")
    } else {
        body = entries.map(\.text).joined(separator: " ")
    }

    return .init(content: [.text(header + body)])
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

    toolsLogger.info("Listing languages for \(videoID)")

    // Fetch caption tracks
    let tracks: [CaptionTrack]
    do {
        tracks = try await TranscriptFetcher.fetchCaptionTracks(videoID: videoID)
    } catch {
        return .init(content: [.text("\(error)")], isError: true)
    }

    if tracks.isEmpty {
        return .init(content: [.text("No captions available for video: \(videoID)")], isError: true)
    }

    let header = "Video ID: \(videoID) | Available languages: \(tracks.count)\n---\n"
    let listing = tracks.map { track in
        let type = track.isAutoGenerated ? "(auto-generated)" : "(manual)"
        return "- \(track.languageCode): \(track.languageName) \(type)"
    }.joined(separator: "\n")

    return .init(content: [.text(header + listing)])
}
