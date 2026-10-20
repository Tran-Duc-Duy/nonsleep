#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

/// Cross-platform process helpers. Platform files (`MacProcesses.swift`, `LinuxProcesses.swift`)
/// provide `startTime(of:)`, `parent(of:)`, `bootTime()`, `allPIDs()`, `arguments(of:)` and
/// `PowerAssertion.all()`.

public enum Processes {
    /// Wrappers a hook command runs under; the agent is the first ancestor that isn't one.
    static let launchers: Set<String> = ["sh", "bash", "zsh", "dash", "fish", "env", "nonsleep"]

    /// The process that ran this hook (Claude Code, Cursor's extension host, Antigravity's
    /// language server…), skipping shells between it and us. `nil` if only launchd is left.
    public static func hookOwner(startingAt pid: pid_t = getppid()) -> pid_t? {
        var current = pid
        while current > 1 {
            let name = (arguments(of: current).first ?? "").split(separator: "/").last.map(String.init) ?? ""
            let base = name.hasPrefix("-") ? String(name.dropFirst()) : name  // login shells: "-zsh"
            if !launchers.contains(base) { return current }
            guard let next = parent(of: current), next != current else { return nil }
            current = next
        }
        return nil
    }

    /// True when `name` is the executable (`claude`) or the script run by an interpreter
    /// (`bun …/omp`, `node …/cli.js`). Case-insensitive, compares basenames only.
    public static func arguments(_ arguments: [String], match name: String) -> Bool {
        arguments.prefix(2).contains { argument in
            let base = argument.split(separator: "/").last.map(String.init) ?? argument
            return base.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    /// PIDs of running processes matching `name` (see `arguments(_:match:)`).
    public static func pids(named name: String) -> [pid_t] {
        allPIDs().filter { arguments(arguments(of: $0), match: name) }
    }
}

public struct PowerAssertion: Sendable, Equatable {
    public var pid: pid_t
    public var name: String

    public init(pid: pid_t, name: String) {
        self.pid = pid
        self.name = name
    }
}
