import Testing
import Foundation
@testable import yt_transcript_mcp

@Suite("Caption URL trust check")
struct CaptionURLTrustTests {
    private func trusted(_ s: String) -> Bool {
        TranscriptFetcher.isTrustedCaptionURL(URL(string: s)!)
    }

    @Test func acceptsYouTubeApex() { #expect(trusted("https://youtube.com/api/timedtext")) }
    @Test func acceptsYouTubeSubdomain() { #expect(trusted("https://www.youtube.com/api/timedtext")) }
    @Test func acceptsGoogleSubdomain() { #expect(trusted("https://video.google.com/timedtext")) }
    @Test func rejectsLookalikeYouTubeHost() { #expect(!trusted("https://evilyoutube.com/api/timedtext")) }
    @Test func rejectsLookalikeGoogleHost() { #expect(!trusted("https://notgoogle.com/x")) }
    @Test func rejectsPlainHTTP() { #expect(!trusted("http://www.youtube.com/api/timedtext")) }
    @Test func rejectsTrustedNameInPath() { #expect(!trusted("https://example.com/youtube.com")) }
}

@Suite("TranscriptFetcher")
struct TranscriptFetcherTests {

    // MARK: - Integration tests (require network)

    @Test func fetchCaptionTracksForKnownVideo() async throws {
        // Rick Astley - Never Gonna Give You Up (known to have captions)
        let result = try await TranscriptFetcher.fetchCaptionTracks(videoID: "dQw4w9WgXcQ")
        #expect(!result.tracks.isEmpty)

        // Should have at least one English track
        let hasEnglish = result.tracks.contains { $0.languageCode.hasPrefix("en") }
        #expect(hasEnglish)

        // Every track should have a non-empty baseURL
        for track in result.tracks {
            #expect(!track.baseURL.isEmpty)
            #expect(!track.languageCode.isEmpty)
        }

        // Metadata should be populated
        #expect(result.metadata.title.contains("Never Gonna Give You Up"))
        #expect(result.metadata.channel == "Rick Astley")
        #expect(result.metadata.durationSeconds > 0)
    }

    @Test func fetchTranscriptForKnownVideo() async throws {
        let result = try await TranscriptFetcher.fetchTranscript(videoID: "dQw4w9WgXcQ")
        #expect(!result.entries.isEmpty)

        // First entry should have a start time of 0 or close to it
        let first = result.entries[0]
        #expect(first.start < 5.0)

        // Entries should have non-empty text
        for entry in result.entries {
            #expect(!entry.text.isEmpty)
        }

        // Should contain some recognizable lyrics
        let allText = result.entries.map(\.text).joined(separator: " ").lowercased()
        #expect(allText.contains("never gonna give you up") || allText.contains("never gonna"))

        // Metadata comes with the transcript
        #expect(!result.metadata.title.isEmpty)
        #expect(!result.metadata.channel.isEmpty)
    }

    @Test func fetchTranscriptWithLanguageFallback() async throws {
        // Request a language that almost certainly doesn't exist
        let result = try await TranscriptFetcher.fetchTranscript(
            videoID: "dQw4w9WgXcQ",
            languageCode: "xx"
        )
        // Should fall back to the first available track
        #expect(!result.entries.isEmpty)
    }

    @Test func fetchCaptionTracksForInvalidVideo() async throws {
        await #expect(throws: TranscriptError.self) {
            try await TranscriptFetcher.fetchCaptionTracks(videoID: "XXXXXXXXXXX")
        }
    }
}
