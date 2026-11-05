#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

/// One agent seen working right now: either a power assertion (macOS) / logind inhibitor (Linux)
/// whose name matches `assertionNames`, or a running process named in `processNames`.
public struct AgentActivity: Codable, Sendable, Equatable {
    public enum Source: String, Codable, Sendable {
        /// A power assertion (macOS) or logind inhibitor (Linux) held by the agent itself.
        case assertion
        /// A process whose mere presence counts as activity.
        case process
    }

    public var name: String
    public var pid: Int32
    public var source: Source

    public init(name: String, pid: Int32, source: Source) {
        self.name = name
        self.pid = pid
        self.source = source
    }

    /// What the CLI and the menu bar app print: "omp agent session · pid 412".
    public var label: String { "\(name) · pid \(pid)" }
}

public enum Agents {
    /// Human-readable descriptions of current agent activity; empty when nothing matches.
    public static func activity(config: Config) -> [String] {
        detected(config: config).map(\.label)
    }

    /// Structured form of `activity(config:)`, for `nonsleep status --json` and its frontends.
    public static func detected(config: Config) -> [AgentActivity] {
        var found = matching(PowerAssertion.all(), names: config.assertionNames)
        for name in config.processNames {
            for pid in Processes.pids(named: name) where pid != getpid() {
                found.append(AgentActivity(name: name, pid: Int32(pid), source: .process))
            }
        }
        return found
    }

    /// Assertions whose name contains one of `names` (case-insensitive), one entry per (pid, name).
    public static func matching(_ assertions: [PowerAssertion], names: [String]) -> [AgentActivity] {
        var seen = Set<String>()
        return assertions
            .filter { assertion in names.contains { assertion.name.localizedCaseInsensitiveContains($0) } }
            .sorted { ($0.pid, $0.name) < ($1.pid, $1.name) }
            .map { AgentActivity(name: $0.name, pid: Int32($0.pid), source: .assertion) }
            .filter { seen.insert($0.label).inserted }
    }
}

/// Debounces agent activity: stays active for `grace` after the last observed activity.
public struct Grace: Sendable {
    /// Adjustable in place so a config change doesn't drop an in-progress grace window.
    public var grace: TimeInterval
    private var lastActive: Date?

    public init(seconds: Int) {
        grace = TimeInterval(seconds)
    }

    public mutating func update(active: Bool, now: Date = Date()) -> Bool {
        if active { lastActive = now }
        guard let lastActive else { return false }
        return now.timeIntervalSince(lastActive) < grace || active
    }
}
