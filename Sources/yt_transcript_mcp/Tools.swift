import MCP

func registerTools(on server: Server) async {
    // List available tools
    await server.withMethodHandler(ListTools.self) { _ in
        ListTools.Result(tools: [
            Tool(
                name: "hello_world",
                description: "A dummy tool that returns a greeting. Used to verify the MCP server is working.",
                inputSchema: .object([
                    "type": .string("object"),
                    "properties": .object([
                        "name": .object([
                            "type": .string("string"),
                            "description": .string("Name to greet (optional)")
                        ])
                    ])
                ])
            )
        ])
    }

    // Handle tool calls
    await server.withMethodHandler(CallTool.self) { params in
        switch params.name {
        case "hello_world":
            let name = params.arguments?["name"]?.stringValue ?? "World"
            return .init(content: [.text("Hello, \(name)! The MCP server is working.")])
        default:
            return .init(content: [.text("Unknown tool: \(params.name)")], isError: true)
        }
    }
}
