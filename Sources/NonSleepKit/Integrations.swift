import Foundation

/// Agents that report turns through hooks. (omp needs none: NonSleep reads its power assertion.)
public enum HookAgent: String, CaseIterable, Sendable, Identifiable {
    case claude, cursor, antigravity

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .claude: "Claude Code"
        case .cursor: "Cursor"
        case .antigravity: "Antigravity"
        }
    }

    /// User-level hooks file. Antigravity's covers the App, the IDE and the CLI.
    public var configURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return switch self {
        case .claude: home.appendingPathComponent(".claude/settings.json")
        case .cursor: home.appendingPathComponent(".cursor/hooks.json")
        case .antigravity: home.appendingPathComponent(".gemini/config/hooks.json")
        }
    }

    /// Subscribed events and what each one means for the current turn.
    var events: [String: HookAction] {
        switch self {
        case .claude:
            // Notification = waiting on the user (permission or idle prompt): nothing to keep awake for.
            [
                "UserPromptSubmit": .working, "PostToolUse": .working,
                "Stop": .finished, "StopFailure": .finished, "Notification": .finished, "SessionEnd": .finished,
            ]
        case .cursor:
            // Observe-only events; permission hooks (preToolUse, beforeShellExecution…) are avoided
            // so NonSleep can never approve or block anything.
            [
                "beforeSubmitPrompt": .working, "postToolUse": .working, "afterShellExecution": .working,
                "afterFileEdit": .working, "afterAgentThought": .working,
                "stop": .finished, "sessionEnd": .finished,
            ]
        case .antigravity:
            ["PreInvocation": .working, "PostToolUse": .working, "Stop": .finished]
        }
    }
}

public enum HookAction: Sendable, Equatable {
    case working, finished
}

public struct HookDecision: Sendable, Equatable {
    /// `nil` for events NonSleep doesn't subscribe to.
    public var action: HookAction?
    public var leaseID: String
    public var reason: String
    /// What the agent expects on stdout; every value lets the agent carry on unchanged.
    public var response: String
}

public enum Hooks {
    public static func decide(agent: HookAgent, event: String, payload: Data) -> HookDecision {
        let json = (try? JSONSerialization.jsonObject(with: payload)) as? [String: Any] ?? [:]
        var action = agent.events[event]
        let session: String?
        let project: String?
        let response: String
        switch agent {
        case .claude:
            session = json["session_id"] as? String
            project = json["cwd"] as? String
            response = ""  // UserPromptSubmit stdout would be added to the model's context
        case .cursor:
            session = (json["conversation_id"] ?? json["session_id"]) as? String
            project = (json["workspace_roots"] as? [String])?.first
            response = event == "beforeSubmitPrompt" ? #"{"continue":true}"# : "{}"
        case .antigravity:
            session = json["conversationId"] as? String
            project = (json["workspacePaths"] as? [String])?.first
            if event == "Stop" {
                // Background commands still running: keep holding until they finish or time out.
                if json["fullyIdle"] as? Bool == false { action = .working }
                response = #"{"decision":"stop"}"#
            } else {
                response = "{}"
            }
        }
        let shortSession = String((session ?? "session").prefix(12))
        let name = project.flatMap { $0.split(separator: "/").last.map(String.init) } ?? shortSession
        return HookDecision(
            action: action, leaseID: "\(agent.rawValue)-\(shortSession)",
            reason: "\(agent.displayName) · \(name)", response: response
        )
    }
}

/// Adds or removes NonSleep's entries in an agent's hooks file, leaving every other hook alone.
public enum Integration {
    public static func command(cli: String, agent: HookAgent, event: String) -> String {
        "'\(cli)' hook \(agent.rawValue) \(event)"
    }

    /// The `nonsleep` binary to put in hook commands: this binary, or the CLI next to the app.
    public static func cliPath() -> String {
        let executable = (Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0]))
            .resolvingSymlinksInPath()
        if executable.lastPathComponent == "nonsleep" { return executable.path }
        return executable.deletingLastPathComponent().appendingPathComponent("nonsleep").path
    }

    // MARK: Files

    public static func isInstalled(_ agent: HookAgent) -> Bool {
        ((try? load(agent.configURL)).map { isInstalled(agent, in: $0) }) ?? false
    }

    public static func install(_ agent: HookAgent, cli: String = cliPath()) throws {
        try save(installing(agent, cli: cli, into: load(agent.configURL)), to: agent.configURL)
    }

    public static func remove(_ agent: HookAgent) throws {
        guard FileManager.default.fileExists(atPath: agent.configURL.path) else { return }
        try save(removing(agent, from: load(agent.configURL)), to: agent.configURL)
    }

    static func load(_ url: URL) throws -> [String: Any] {
        guard let data = try? Data(contentsOf: url), !data.isEmpty else { return [:] }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NonSleepError.invalidConfig(url, "top level is not a JSON object")
        }
        return object
    }

    /// Keeps the first pre-NonSleep version as `<file>.nonsleep-backup`.
    static func save(_ object: [String: Any], to url: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let backup = url.appendingPathExtension("nonsleep-backup")
        if fileManager.fileExists(atPath: url.path), !fileManager.fileExists(atPath: backup.path) {
            try fileManager.copyItem(at: url, to: backup)
        }
        let data = try JSONSerialization.data(
            withJSONObject: object, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        try data.write(to: url, options: .atomic)
    }

    // MARK: Pure transforms

    /// Antigravity groups hooks under named top-level definitions; this one is ours.
    static let antigravityKey = "nonsleep"

    public static func isInstalled(_ agent: HookAgent, in config: [String: Any]) -> Bool {
        switch agent {
        case .antigravity:
            return config[antigravityKey] != nil
        case .claude, .cursor:
            let hooks = config["hooks"] as? [String: Any] ?? [:]
            return hooks.values.contains { entries in
                (entries as? [[String: Any]] ?? []).contains { isOurs($0, agent) }
            }
        }
    }

    /// Idempotent: replaces any previous NonSleep entries (e.g. after the app moved).
    public static func installing(_ agent: HookAgent, cli: String, into config: [String: Any]) -> [String: Any] {
        var config = removing(agent, from: config)
        let handler = { (event: String) -> [String: Any] in
            ["type": "command", "command": command(cli: cli, agent: agent, event: event), "timeout": 10]
        }
        switch agent {
        case .claude:
            var hooks = config["hooks"] as? [String: Any] ?? [:]
            for event in agent.events.keys {
                hooks[event] = (hooks[event] as? [[String: Any]] ?? []) + [["hooks": [handler(event)]]]
            }
            config["hooks"] = hooks
        case .cursor:
            var hooks = config["hooks"] as? [String: Any] ?? [:]
            for event in agent.events.keys {
                var entry = handler(event)
                entry["type"] = nil  // Cursor's command hooks have no type field
                hooks[event] = (hooks[event] as? [[String: Any]] ?? []) + [entry]
            }
            config["hooks"] = hooks
            config["version"] = config["version"] ?? 1
        case .antigravity:
            var definition: [String: Any] = [:]
            for event in agent.events.keys {
                // Tool events nest handlers under a matcher; the others list handlers directly.
                definition[event] = event.hasSuffix("ToolUse")
                    ? [["matcher": "*", "hooks": [handler(event)]]]
                    : [handler(event)]
            }
            config[antigravityKey] = definition
        }
        return config
    }

    public static func removing(_ agent: HookAgent, from config: [String: Any]) -> [String: Any] {
        var config = config
        switch agent {
        case .antigravity:
            config[antigravityKey] = nil
        case .claude, .cursor:
            guard var hooks = config["hooks"] as? [String: Any] else { return config }
            for (event, value) in hooks {
                guard let entries = value as? [[String: Any]] else { continue }
                let kept = entries.compactMap { entry -> [String: Any]? in
                    if agent == .cursor { return isOurs(entry, agent) ? nil : entry }
                    // Claude: drop our handlers inside each matcher group, then empty groups.
                    guard var inner = entry["hooks"] as? [[String: Any]] else { return entry }
                    inner.removeAll { isOurs($0, agent) }
                    if inner.isEmpty { return nil }
                    var group = entry
                    group["hooks"] = inner
                    return group
                }
                hooks[event] = kept.isEmpty ? nil : kept
            }
            config["hooks"] = hooks.isEmpty ? nil : hooks
        }
        return config
    }

    private static func isOurs(_ entry: [String: Any], _ agent: HookAgent) -> Bool {
        if agent == .claude, let inner = entry["hooks"] as? [[String: Any]] {
            return inner.contains { isOurs($0, agent) }
        }
        let command = entry["command"] as? String ?? ""
        return command.contains("/nonsleep' hook \(agent.rawValue) ")
    }
}
