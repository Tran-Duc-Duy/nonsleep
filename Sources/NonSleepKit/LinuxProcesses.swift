#if os(Linux)
import Foundation
import Glibc

extension Processes {
    /// Start time in clock ticks since boot (field 22 of `/proc/<pid>/stat`); `nil` when the process
    /// does not exist. Only compared for equality, as a guard against PID reuse.
    public static func startTime(of pid: pid_t) -> UInt64? {
        LinuxParse.stat(Proc.text("/proc/\(pid)/stat")).map(\.start)
    }

    public static func parent(of pid: pid_t) -> pid_t? {
        LinuxParse.stat(Proc.text("/proc/\(pid)/stat")).map(\.parent)
    }

    /// Boot time in seconds since the epoch. Leases never survive a reboot.
    public static func bootTime() -> UInt64 {
        LinuxParse.bootTime(Proc.text("/proc/stat")) ?? 0
    }

    public static func allPIDs() -> [pid_t] {
        ((try? FileManager.default.contentsOfDirectory(atPath: "/proc")) ?? []).compactMap { pid_t($0) }
    }

    /// `argv` of a process; empty if unreadable (other users' processes may hide it).
    public static func arguments(of pid: pid_t) -> [String] {
        LinuxParse.cmdline(Proc.data("/proc/\(pid)/cmdline"))
    }
}

extension PowerAssertion {
    /// logind inhibitor locks (what `systemd-inhibit --list` shows), named by their "why".
    /// NonSleep's own lock is left out.
    public static func all() -> [PowerAssertion] {
        guard let result = try? Command.run("/usr/bin/env", [
            "busctl", "--json=short", "call", "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", "ListInhibitors",
        ]), result.status == 0 else { return [] }
        return LinuxParse.inhibitors(result.stdout)
            .filter { $0.who != Keeper.who }
            .map { PowerAssertion(pid: $0.pid, name: $0.why.isEmpty ? $0.who : $0.why) }
    }
}

/// `/proc` files report size 0, so read them to EOF instead of trusting `stat`.
enum Proc {
    static func data(_ path: String) -> Data {
        guard let handle = FileHandle(forReadingAtPath: path) else { return Data() }
        defer { try? handle.close() }
        return handle.readDataToEndOfFile()
    }

    static func text(_ path: String) -> String {
        String(decoding: data(path), as: UTF8.self)
    }
}
#endif
