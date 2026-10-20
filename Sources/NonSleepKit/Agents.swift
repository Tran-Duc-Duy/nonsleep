#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

public enum Agents {
    /// Human-readable descriptions of current agent activity; empty when nothing matches.
    public static func activity(config: Config) -> [String] {
        var found = matching(PowerAssertion.all(), names: config.assertionNames)
        for name in config.processNames {
            for pid in Processes.pids(named: name) where pid != getpid() {
                found.append("\(name) · pid \(pid)")
            }
        }
        return found
    }

    /// Assertions whose name contains one of `names` (case-insensitive), one entry per (pid, name).
    public static func matching(_ assertions: [PowerAssertion], names: [String]) -> [String] {
        var seen = Set<String>()
        return assertions
            .filter { assertion in names.contains { assertion.name.localizedCaseInsensitiveContains($0) } }
            .sorted { ($0.pid, $0.name) < ($1.pid, $1.name) }
            .map { "\($0.name) · pid \($0.pid)" }
            .filter { seen.insert($0).inserted }
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
