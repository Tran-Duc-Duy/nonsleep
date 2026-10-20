#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

/// A request to keep the Mac awake with the lid closed. The flag stays on while any lease is alive.
///
/// A lease dies when it expires, when its owner process exits, or on reboot. Dead leases are
/// swept by whoever reconciles next (CLI, menu bar app, or the LaunchAgent reaper), so a crash
/// can never leave the Mac permanently unable to sleep.
public struct Lease: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var reason: String
    /// `nil` for detached leases (e.g. `nonsleep on 3h`), which live until expiry, `off`, or reboot.
    public var ownerPID: pid_t?
    public var ownerStart: UInt64?
    public var bootTime: UInt64
    public var expiresAt: Date?

    public init(id: String, reason: String, ownerPID: pid_t?, ownerStart: UInt64?, bootTime: UInt64, expiresAt: Date?) {
        self.id = id
        self.reason = reason
        self.ownerPID = ownerPID
        self.ownerStart = ownerStart
        self.bootTime = bootTime
        self.expiresAt = expiresAt
    }

    /// A lease that dies with process `pid` (default: the calling process).
    public static func owned(id: String, reason: String, by pid: pid_t = getpid(), expiresAt: Date? = nil) -> Lease {
        Lease(
            id: id, reason: reason, ownerPID: pid, ownerStart: Processes.startTime(of: pid),
            bootTime: Processes.bootTime(), expiresAt: expiresAt
        )
    }

    /// A lease that outlives the calling process.
    public static func detached(id: String, reason: String, expiresAt: Date?) -> Lease {
        Lease(id: id, reason: reason, ownerPID: nil, ownerStart: nil, bootTime: Processes.bootTime(), expiresAt: expiresAt)
    }

    /// "pid 123", "detached", plus ", until 16:20" when the lease expires.
    public var detail: String {
        let owner = ownerPID.map { "pid \($0)" } ?? "detached"
        guard let expiresAt else { return owner }
        return "\(owner), until \(expiresAt.formatted(date: .omitted, time: .shortened))"
    }

    /// - Parameter ownerStart: current start time of `ownerPID`, `nil` if that process is gone.
    public func isAlive(now: Date, bootTime: UInt64, ownerStart current: UInt64?) -> Bool {
        guard self.bootTime == bootTime else { return false }
        if let expiresAt, expiresAt <= now { return false }
        guard ownerPID != nil else { return true }
        return current != nil && current == ownerStart
    }
}

/// On-disk state shared by every NonSleep process: `<directory>/leases/*.json`, a lock file,
/// and an ownership marker recording that NonSleep (not another tool) set the flag.
public struct Store: Sendable {
    public let directory: URL
    public let configURL: URL

    public init(directory: URL, configURL: URL? = nil) {
        self.directory = directory
        self.configURL = configURL ?? directory.appendingPathComponent("config.json")
    }

    /// macOS: `~/Library/Application Support/NonSleep`. Linux (XDG): state in
    /// `~/.local/state/nonsleep`, config in `~/.config/nonsleep/config.json`.
    public static var standard: Store {
        let home = FileManager.default.homeDirectoryForCurrentUser
        #if os(macOS)
        return Store(directory: home.appendingPathComponent("Library/Application Support/NonSleep", isDirectory: true))
        #else
        let environment = ProcessInfo.processInfo.environment
        let state = environment["XDG_STATE_HOME"].map { URL(fileURLWithPath: $0) } ?? home.appendingPathComponent(".local/state")
        let config = environment["XDG_CONFIG_HOME"].map { URL(fileURLWithPath: $0) } ?? home.appendingPathComponent(".config")
        return Store(
            directory: state.appendingPathComponent("nonsleep", isDirectory: true),
            configURL: config.appendingPathComponent("nonsleep/config.json")
        )
        #endif
    }

    private var leaseDirectory: URL { directory.appendingPathComponent("leases", isDirectory: true) }
    private var ownerMarker: URL { directory.appendingPathComponent("owns-flag") }

    public func leases() -> [Lease] {
        let files = (try? FileManager.default.contentsOfDirectory(at: leaseDirectory, includingPropertiesForKeys: nil)) ?? []
        let decoder = JSONDecoder()
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(Lease.self, from: Data(contentsOf: $0)) }
            .sorted { $0.id < $1.id }
    }

    public func save(_ lease: Lease) throws {
        try FileManager.default.createDirectory(at: leaseDirectory, withIntermediateDirectories: true)
        try JSONEncoder().encode(lease).write(to: file(for: lease.id), options: .atomic)
    }

    public func remove(id: String) {
        try? FileManager.default.removeItem(at: file(for: id))
    }

    public var ownsFlag: Bool {
        get { FileManager.default.fileExists(atPath: ownerMarker.path) }
        nonmutating set {
            if newValue {
                _ = FileManager.default.createFile(atPath: ownerMarker.path, contents: nil)
            } else {
                try? FileManager.default.removeItem(at: ownerMarker)
            }
        }
    }

    /// Serializes read-decide-apply across processes.
    public func locked<T>(_ body: () throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = open(directory.appendingPathComponent(".lock").path, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard fd >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(fd) }
        while flock(fd, LOCK_EX) != 0 {
            guard errno == EINTR else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        }
        defer { flock(fd, LOCK_UN) }
        return try body()
    }

    private func file(for id: String) -> URL {
        let safe = id.map { $0.isLetter || $0.isNumber || $0 == "-" ? $0 : "_" }
        return leaseDirectory.appendingPathComponent(String(safe) + ".json")
    }
}
