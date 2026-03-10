import Testing
@testable import yt_transcript_mcp

@Suite("VideoIDExtractor")
struct VideoIDExtractorTests {

    // MARK: - Standard URL formats

    @Test func watchURL() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func watchURLNoWWW() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func watchURLHTTP() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "http://www.youtube.com/watch?v=dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func shortURL() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://youtu.be/dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func embedURL() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://www.youtube.com/embed/dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func shortsURL() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://www.youtube.com/shorts/dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func legacyVURL() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://www.youtube.com/v/dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    // MARK: - Extra query params and timestamps

    @Test func watchURLWithTimestamp() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func watchURLWithExtraParams() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://www.youtube.com/watch?feature=share&v=dQw4w9WgXcQ&list=PLtest")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func shortURLWithTimestamp() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://youtu.be/dQw4w9WgXcQ?t=120")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func shortURLWithSIParam() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "https://youtu.be/dQw4w9WgXcQ?si=abc123")
        #expect(id == "dQw4w9WgXcQ")
    }

    // MARK: - Raw video ID

    @Test func rawVideoID() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "dQw4w9WgXcQ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func rawVideoIDWithWhitespace() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "  dQw4w9WgXcQ  ")
        #expect(id == "dQw4w9WgXcQ")
    }

    @Test func rawVideoIDWithHyphen() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "a1B2c3D4e-f")
        #expect(id == "a1B2c3D4e-f")
    }

    @Test func rawVideoIDWithUnderscore() throws {
        let id = try VideoIDExtractor.extractVideoID(from: "a1B2c3D4e_f")
        #expect(id == "a1B2c3D4e_f")
    }

    // MARK: - Invalid input

    @Test func emptyString() throws {
        #expect(throws: TranscriptError.self) {
            try VideoIDExtractor.extractVideoID(from: "")
        }
    }

    @Test func randomText() throws {
        #expect(throws: TranscriptError.self) {
            try VideoIDExtractor.extractVideoID(from: "not a youtube url")
        }
    }

    @Test func tooShortID() throws {
        #expect(throws: TranscriptError.self) {
            try VideoIDExtractor.extractVideoID(from: "abc123")
        }
    }

    @Test func tooLongID() throws {
        #expect(throws: TranscriptError.self) {
            try VideoIDExtractor.extractVideoID(from: "dQw4w9WgXcQx")
        }
    }

    @Test func wrongDomain() throws {
        #expect(throws: TranscriptError.self) {
            try VideoIDExtractor.extractVideoID(from: "https://vimeo.com/12345678901")
        }
    }
}
