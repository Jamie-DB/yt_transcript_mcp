import Testing
import Foundation
@testable import yt_transcript_mcp

@Suite("Caption XML Parsing")
struct CaptionXMLParserTests {

    // MARK: - Basic parsing

    @Test func parsesStartAndDuration() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="1.5" dur="3.2">Hello world</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries.count == 1)
        #expect(entries[0].start == 1.5)
        #expect(entries[0].duration == 3.2)
        #expect(entries[0].text == "Hello world")
    }

    @Test func parsesMultipleEntries() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="0.0" dur="2.0">First line</text>
            <text start="2.0" dur="3.0">Second line</text>
            <text start="5.0" dur="1.5">Third line</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries.count == 3)
    }

    @Test func preservesOrder() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="10.0" dur="1.0">Later</text>
            <text start="0.0" dur="1.0">Earlier</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].text == "Later")
        #expect(entries[1].text == "Earlier")
    }

    @Test func defaultsToZeroForMissingAttributes() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text>No attributes</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].start == 0.0)
        #expect(entries[0].duration == 0.0)
    }

    // MARK: - HTML entity decoding

    @Test func decodesAmpersand() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="0" dur="1">Tom &amp; Jerry</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].text == "Tom & Jerry")
    }

    @Test func decodesAngleBrackets() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="0" dur="1">&lt;bold&gt;</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].text == "<bold>")
    }

    @Test func decodesQuotesAndApostrophes() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="0" dur="1">She said &quot;it&#39;s fine&quot;</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].text == "She said \"it's fine\"")
    }

    @Test func replacesNewlinesWithSpaces() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="0" dur="1">Line one\nLine two</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].text == "Line one Line two")
    }

    @Test func trimsWhitespace() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="0" dur="1">  padded text  </text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].text == "padded text")
    }

    @Test func multipleEntitiesInOneString() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
            <text start="0" dur="1">A &amp; B &lt; C &gt; D</text>
        </transcript>
        """
        let entries = try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        #expect(entries[0].text == "A & B < C > D")
    }

    // MARK: - Error cases

    @Test func throwsOnEmptyXML() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <transcript>
        </transcript>
        """
        #expect(throws: TranscriptError.self) {
            try TranscriptFetcher.parseCaptionXML(xml.data(using: .utf8)!)
        }
    }

    @Test func throwsOnInvalidXML() throws {
        let data = "this is not xml".data(using: .utf8)!
        #expect(throws: TranscriptError.self) {
            try TranscriptFetcher.parseCaptionXML(data)
        }
    }
}
