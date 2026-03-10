import Testing
@testable import yt_transcript_mcp

@Suite("TranscriptFetcher")
struct TranscriptFetcherTests {

    // MARK: - Integration tests (require network)

    @Test func fetchCaptionTracksForKnownVideo() async throws {
        // Rick Astley - Never Gonna Give You Up (known to have captions)
        let tracks = try await TranscriptFetcher.fetchCaptionTracks(videoID: "dQw4w9WgXcQ")
        #expect(!tracks.isEmpty)

        // Should have at least one English track
        let hasEnglish = tracks.contains { $0.languageCode.hasPrefix("en") }
        #expect(hasEnglish)

        // Every track should have a non-empty baseURL
        for track in tracks {
            #expect(!track.baseURL.isEmpty)
            #expect(!track.languageCode.isEmpty)
        }
    }

    @Test func fetchTranscriptForKnownVideo() async throws {
        let entries = try await TranscriptFetcher.fetchTranscript(videoID: "dQw4w9WgXcQ")
        #expect(!entries.isEmpty)

        // First entry should have a start time of 0 or close to it
        let first = entries[0]
        #expect(first.start < 5.0)

        // Entries should have non-empty text
        for entry in entries {
            #expect(!entry.text.isEmpty)
        }

        // Should contain some recognizable lyrics
        let allText = entries.map(\.text).joined(separator: " ").lowercased()
        #expect(allText.contains("never gonna give you up") || allText.contains("never gonna"))
    }

    @Test func fetchTranscriptWithLanguageFallback() async throws {
        // Request a language that almost certainly doesn't exist
        let entries = try await TranscriptFetcher.fetchTranscript(
            videoID: "dQw4w9WgXcQ",
            languageCode: "xx"
        )
        // Should fall back to the first available track
        #expect(!entries.isEmpty)
    }

    @Test func fetchCaptionTracksForInvalidVideo() async throws {
        await #expect(throws: TranscriptError.self) {
            try await TranscriptFetcher.fetchCaptionTracks(videoID: "XXXXXXXXXXX")
        }
    }
}
