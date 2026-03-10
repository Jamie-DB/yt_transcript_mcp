import Foundation

enum TranscriptError: Error, CustomStringConvertible {
    case invalidVideoURL(String)
    case networkError(String)
    case noCaptionsAvailable(String)
    case captionTrackNotFound(String)
    case parsingError(String)

    var description: String {
        switch self {
        case .invalidVideoURL(let input):
            return "Could not extract a valid YouTube video ID from: \(input)"
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .noCaptionsAvailable(let videoID):
            return "No captions available for video: \(videoID)"
        case .captionTrackNotFound(let language):
            return "Caption track not found for language: \(language)"
        case .parsingError(let detail):
            return "Failed to parse transcript data: \(detail)"
        }
    }
}

enum VideoIDExtractor {

    // YouTube video IDs are exactly 11 characters: [A-Za-z0-9_-]
    private static let videoIDPattern = "[A-Za-z0-9_-]{11}"

    // Ordered list of patterns to try. The first match wins.
    private static let urlPatterns: [NSRegularExpression] = {
        let patterns = [
            // youtu.be/VIDEO_ID (with optional query/fragment)
            #"(?:https?://)?youtu\.be/(\#(videoIDPattern))"#,
            // youtube.com/watch?v=VIDEO_ID
            #"(?:https?://)?(?:www\.)?youtube\.com/watch\?.*?v=(\#(videoIDPattern))"#,
            // youtube.com/embed/VIDEO_ID
            #"(?:https?://)?(?:www\.)?youtube\.com/embed/(\#(videoIDPattern))"#,
            // youtube.com/shorts/VIDEO_ID
            #"(?:https?://)?(?:www\.)?youtube\.com/shorts/(\#(videoIDPattern))"#,
            // youtube.com/v/VIDEO_ID (legacy)
            #"(?:https?://)?(?:www\.)?youtube\.com/v/(\#(videoIDPattern))"#,
        ]
        // These are compile-time constants. If one fails, that's a developer error.
        return patterns.map { try! NSRegularExpression(pattern: $0) }
    }()

    /// Extracts an 11-character YouTube video ID from a URL string or raw ID.
    /// Throws `TranscriptError.invalidVideoURL` if no valid ID can be found.
    static func extractVideoID(from input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if the input is already a raw 11-char video ID
        if let _ = trimmed.wholeMatch(of: /^[A-Za-z0-9_-]{11}$/) {
            return trimmed
        }

        // Try each URL pattern
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        for regex in urlPatterns {
            if let match = regex.firstMatch(in: trimmed, range: range),
               let idRange = Range(match.range(at: 1), in: trimmed) {
                return String(trimmed[idRange])
            }
        }

        throw TranscriptError.invalidVideoURL(trimmed)
    }
}
