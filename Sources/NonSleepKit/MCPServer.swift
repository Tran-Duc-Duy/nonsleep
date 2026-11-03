import Foundation

public final class MCPServer: Sendable {
    public let engine: NonSleep

    public init(engine: NonSleep = NonSleep()) {
        self.engine = engine
    }

    public func run() throws {
        // Read JSON-RPC lines from standard input until EOF
        while let line = readLine() {
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            guard let data = line.data(using: .utf8),
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                continue
            }
            handleMessage(json)
        }
    }

    private func handleMessage(_ msg: [String: Any]) {
        // `"id": null` decodes to NSNull, which is non-nil and would be echoed back as `null`.
        // JSON-RPC treats it as a notification: no response at all.
        let id = msg["id"].flatMap { $0 is NSNull ? nil : $0 }
        guard let method = msg["method"] as? String else { return }
        let params = msg["params"] as? [String: Any] ?? [:]

        switch method {
        case "initialize":
            sendResponse(id: id, result: [
                "protocolVersion": "2024-11-05",
                "capabilities": [
                    "tools": [:] as [String: Any]
                ],
                "serverInfo": [
                    "name": "nonsleep",
                    "version": NonSleepVersion.current
                ]
            ])

        case "notifications/initialized":
            // Notification: no response required
            break

        case "ping":
            sendResponse(id: id, result: [:])

        case "tools/list":
            let tools: [[String: Any]] = [
                [
                    "name": "nonsleep_status",
                    "description": "Get current NonSleep power mode, lid state, battery %, thermal state, and active leases.",
                    "inputSchema": [
                        "type": "object",
                        "properties": [:] as [String: Any]
                    ]
                ],
                [
                    "name": "nonsleep_acquire_lease",
                    "description": "Keep the Mac awake even with the lid closed while an agent task or command is active.",
                    "inputSchema": [
                        "type": "object",
                        "properties": [
                            "reason": [
                                "type": "string",
                                "description": "Short description of the task keeping the machine awake (e.g. 'Running test suite')"
                            ],
                            "duration_minutes": [
                                "type": "number",
                                "description": "Optional timeout in minutes (default: 30, max: 480)"
                            ]
                        ],
                        "required": ["reason"]
                    ]
                ],
                [
                    "name": "nonsleep_release_lease",
                    "description": "Release a NonSleep lease to allow the computer to sleep normally when finished.",
                    "inputSchema": [
                        "type": "object",
                        "properties": [
                            "lease_id": [
                                "type": "string",
                                "description": "Optional lease ID to release. If omitted, releases all leases for this session."
                            ]
                        ]
                    ]
                ]
            ]
            sendResponse(id: id, result: ["tools": tools])

        case "tools/call":
            guard let toolName = params["name"] as? String else {
                sendError(id: id, code: -32602, message: "Missing tool name")
                return
            }
            let args = params["arguments"] as? [String: Any] ?? [:]
            executeTool(name: toolName, arguments: args, id: id)

        default:
            if id != nil {
                sendError(id: id, code: -32601, message: "Method not found: \(method)")
            }
        }
    }

    private func executeTool(name: String, arguments: [String: Any], id: Any?) {
        do {
            switch name {
            case "nonsleep_status":
                let status = try engine.reconcile()
                let power = status.power
                var text = "\(status.headline)\n"
                text += "• Power: \(power.onBattery ? "Battery (\(power.batteryPercent.map { "\($0)%" } ?? "unknown"))" : "AC Power")\n"
                text += "• Lid: \(power.lidClosed ? "Closed" : "Open")\n"
                text += "• Thermal: \(power.thermal.rawValue)\n"
                if status.leases.isEmpty {
                    text += "• Leases: None (Normal sleep allowed)\n"
                } else {
                    text += "• Active Leases:\n"
                    for lease in status.leases {
                        text += "  - [\(lease.id)] \(lease.reason) (\(lease.detail))\n"
                    }
                }
                sendToolResult(id: id, text: text)

            case "nonsleep_acquire_lease":
                guard let reason = arguments["reason"] as? String, !reason.isEmpty else {
                    sendError(id: id, code: -32602, message: "Missing required argument 'reason'")
                    return
                }
                let minutes = min(480, max(1, (arguments["duration_minutes"] as? Double) ?? 30.0))
                let expiresAt = Date().addingTimeInterval(minutes * 60)
                let leaseID = "mcp-\(UUID().uuidString.prefix(8).lowercased())"
                let lease = Lease.detached(id: leaseID, reason: "[MCP] \(reason)", expiresAt: expiresAt)
                let status = try engine.hold(lease)
                let text = "Lease acquired successfully.\n• ID: \(leaseID)\n• Reason: \(reason)\n• Expires in: \(Int(minutes)) minutes\n• Machine state: \(status.headline)"
                sendToolResult(id: id, text: text)

            case "nonsleep_release_lease":
                if let leaseID = arguments["lease_id"] as? String, !leaseID.isEmpty {
                    let status = try engine.release(id: leaseID)
                    sendToolResult(id: id, text: "Lease '\(leaseID)' released. Current state: \(status.headline)")
                } else {
                    let status = try engine.releaseAll()
                    sendToolResult(id: id, text: "All leases released. Machine can sleep when lid is closed. Current state: \(status.headline)")
                }

            default:
                sendError(id: id, code: -32601, message: "Unknown tool: \(name)")
            }
        } catch {
            sendToolResult(id: id, text: "Error executing \(name): \(error)", isError: true)
        }
    }

    private func sendToolResult(id: Any?, text: String, isError: Bool = false) {
        sendResponse(id: id, result: [
            "content": [
                [
                    "type": "text",
                    "text": text
                ]
            ],
            "isError": isError
        ])
    }

    private func sendResponse(id: Any?, result: [String: Any]) {
        guard let id else { return }
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "result": result
        ]
        send(payload)
    }

    private func sendError(id: Any?, code: Int, message: String) {
        guard let id else { return }
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "error": [
                "code": code,
                "message": message
            ]
        ]
        send(payload)
    }

    /// One line per message, written straight to fd 1.
    ///
    /// Not `print` + `fflush(stdout)`: on Glibc `stdout` is a mutable global, which Swift 6
    /// rejects as shared mutable state (Darwin imports it differently, so macOS never flagged
    /// it). `FileHandle.write` is an unbuffered `write(2)`, so the flush the client needs after
    /// every response is inherent rather than bolted on.
    private func send(_ object: [String: Any]) {
        guard var data = try? JSONSerialization.data(withJSONObject: object) else { return }
        data.append(0x0A)  // JSON-RPC over stdio is newline-delimited.
        FileHandle.standardOutput.write(data)
    }
}
