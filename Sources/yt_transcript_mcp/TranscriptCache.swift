import Logging

/// In-memory cache for transcript data. Lives for the duration of the MCP server process
/// (one session). Avoids redundant network calls when the same video is referenced
/// multiple times in a conversation.
actor TranscriptCache {

    private let logger = Logger(label: "yt_transcript_mcp.cache")

    // Caption tracks + metadata, keyed by video ID
    private var captionTrackResults: [String: CaptionTrackResult] = [:]

    // Full transcript results, keyed by "videoID:language"
    private var transcriptResults: [String: TranscriptResult] = [:]

    private func transcriptKey(videoID: String, language: String?) -> String {
        "\(videoID):\(language ?? "default")"
    }

    // MARK: - Caption Tracks

    func getCaptionTracks(videoID: String) -> CaptionTrackResult? {
        let result = captionTrackResults[videoID]
        if result != nil {
            logger.debug("Cache hit: caption tracks for \(videoID)")
        }
        return result
    }

    func storeCaptionTracks(_ result: CaptionTrackResult, videoID: String) {
        captionTrackResults[videoID] = result
        logger.debug("Cached caption tracks for \(videoID)")
    }

    // MARK: - Transcripts

    func getTranscript(videoID: String, language: String?) -> TranscriptResult? {
        let key = transcriptKey(videoID: videoID, language: language)
        let result = transcriptResults[key]
        if result != nil {
            logger.debug("Cache hit: transcript for \(key)")
        }
        return result
    }

    func storeTranscript(_ result: TranscriptResult, videoID: String, language: String?) {
        let key = transcriptKey(videoID: videoID, language: language)
        transcriptResults[key] = result
        logger.debug("Cached transcript for \(key)")
    }
}
