import Foundation
import MCP
import Logging

// Configure logging to stderr (stdout is reserved for JSON-RPC)
LoggingSystem.bootstrap { label in
    var handler = StreamLogHandler.standardError(label: label)
    let logLevel: Logger.Level = {
        if let env = ProcessInfo.processInfo.environment["YT_TRANSCRIPT_LOG_LEVEL"],
           let level = Logger.Level(rawValue: env) {
            return level
        }
        return .info
    }()
    handler.logLevel = logLevel
    return handler
}

let logger = Logger(label: "yt_transcript_mcp")
logger.info("Starting yt_transcript_mcp server...")

// Create server with tool capabilities
let server = Server(
    name: "yt_transcript_mcp",
    version: "0.1.0",
    capabilities: .init(
        tools: .init(listChanged: false)
    )
)

// Register tool handlers
await registerTools(on: server)

// Start listening on stdio
let transport = StdioTransport()
try await server.start(transport: transport)
logger.info("Server started, waiting for requests...")

await server.waitUntilCompleted()
