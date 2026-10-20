#if os(macOS)
import Foundation

/// The one-time system setup NonSleep needs, and whether it is in place:
/// - a sudoers rule allowing exactly `pmset -a disablesleep 0|1` without a password,
/// - the reaper LaunchAgent (`nonsleep reap` at login and every minute),
/// - a `nonsleep` symlink in `~/.local/bin` for the terminal.
public enum Setup {
    public static let sudoersPath = "/etc/sudoers.d/nonsleep"
    public static let reaperLabel = "dev.nonsleep.reaper"

    public static var reaperPlistURL: URL {
        home.appendingPathComponent("Library/LaunchAgents/\(reaperLabel).plist")
    }

    public static var cliLinkURL: URL { home.appendingPathComponent(".local/bin/nonsleep") }

    /// `sudo -l` can't tell our NOPASSWD rule from admin rights, so check for the file itself.
    public static var sudoersInstalled: Bool { FileManager.default.fileExists(atPath: sudoersPath) }
    public static var reaperInstalled: Bool { FileManager.default.fileExists(atPath: reaperPlistURL.path) }

    private static var home: URL { FileManager.default.homeDirectoryForCurrentUser }

    // MARK: Install / remove

    /// Installs whatever is missing. The sudoers step shows the macOS administrator dialog once.
    /// - Parameter cli: absolute path of the `nonsleep` binary the reaper and the symlink point to.
    public static func install(cli: String) throws {
        try installReaper(cli: cli)
        try linkCLI(cli)
        if !sudoersInstalled { try installSudoers(user: NSUserName()) }
    }

    public static func remove() throws {
        _ = try? Command.run("/bin/launchctl", ["bootout", "gui/\(getuid())/\(reaperLabel)"])
        try? FileManager.default.removeItem(at: reaperPlistURL)
        if (try? FileManager.default.destinationOfSymbolicLink(atPath: cliLinkURL.path)) != nil {
            try? FileManager.default.removeItem(at: cliLinkURL)
        }
        if sudoersInstalled { try runAsAdministrator("/bin/rm -f \(shellQuoted(sudoersPath))") }
    }

    /// `nil` for names that must not be pasted into sudoers.
    static func sudoersRule(user: String) -> String? {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        guard !user.isEmpty, !user.hasPrefix("-"), user.allSatisfy(allowed.contains) else { return nil }
        return "\(user) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1\n"
    }

    static func reaperPlist(cli: String) throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: [
                "Label": reaperLabel,
                "ProgramArguments": [cli, "reap"],
                "RunAtLoad": true,
                "StartInterval": 60,
                "ProcessType": "Background",
            ] as [String: Any],
            format: .xml, options: 0
        )
    }

    private static func installReaper(cli: String) throws {
        try FileManager.default.createDirectory(
            at: reaperPlistURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try reaperPlist(cli: cli).write(to: reaperPlistURL, options: .atomic)
        let domain = "gui/\(getuid())"
        _ = try? Command.run("/bin/launchctl", ["bootout", "\(domain)/\(reaperLabel)"])
        let result = try Command.run("/bin/launchctl", ["bootstrap", domain, reaperPlistURL.path])
        guard result.status == 0 else { throw NonSleepError.setupFailed("launchctl bootstrap: \(result.stderr)") }
    }

    private static func linkCLI(_ cli: String) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: cliLinkURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if (try? fileManager.destinationOfSymbolicLink(atPath: cliLinkURL.path)) != nil {
            try fileManager.removeItem(at: cliLinkURL)
        } else if fileManager.fileExists(atPath: cliLinkURL.path) {
            return  // a real file someone put there; leave it alone
        }
        try fileManager.createSymbolicLink(atPath: cliLinkURL.path, withDestinationPath: cli)
    }

    private static func installSudoers(user: String) throws {
        guard let rule = sudoersRule(user: user) else {
            throw NonSleepError.setupFailed("user name \"\(user)\" can't be used in a sudoers rule")
        }
        let draft = FileManager.default.temporaryDirectory.appendingPathComponent("nonsleep-sudoers-\(UUID().uuidString)")
        try rule.write(to: draft, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: draft) }
        let path = shellQuoted(draft.path)
        try runAsAdministrator(
            "/usr/sbin/visudo -cf \(path) >/dev/null && /usr/bin/install -m 0440 -o root -g wheel \(path) \(shellQuoted(sudoersPath))"
        )
    }

    /// The standard macOS administrator dialog (password or Touch ID), via `osascript`.
    private static func runAsAdministrator(_ shellCommand: String) throws {
        let literal = "\"" + shellCommand.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
        let result = try Command.run(
            "/usr/bin/osascript",
            ["-e", "do shell script \(literal) with prompt \"NonSleep needs to allow pmset disablesleep.\" with administrator privileges"]
        )
        guard result.status == 0 else { throw NonSleepError.setupFailed(result.stderr) }
    }

    private static func shellQuoted(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    // MARK: Screen lock

    /// The macOS screen-lock delay ("immediate", "300 seconds", "off"…); `nil` if unknown.
    /// Turning the display off on lid close only locks the Mac when this is "immediate".
    public static func screenLockDelay() -> String? {
        guard let result = try? Command.run("/usr/sbin/sysadminctl", ["-screenLock", "status"]),
              let range = result.stderr.range(of: "screenLock ")
        else { return nil }
        // e.g. "… screenLock delay is immediate" or "… screenLock is off"
        var detail = String(result.stderr[range.upperBound...])
        for prefix in ["delay is ", "is "] where detail.hasPrefix(prefix) {
            detail.removeFirst(prefix.count)
            break
        }
        return detail
    }
}
#endif
