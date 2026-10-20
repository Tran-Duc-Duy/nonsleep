#if os(Linux)
import Foundation
import Glibc

/// Linux: lid-closed mode is a logind inhibitor lock (`handle-lid-switch:sleep`, block mode) held by
/// a small `nonsleep keeper` process that runs only while a live lease exists. No root is needed,
/// and if the keeper or `systemd-inhibit` dies, logind drops the lock: a failure always means
/// "the laptop can sleep again", never "stuck awake".
public struct SystemPower: PowerControl {
    let store: Store

    public init(store: Store = .standard) {
        self.store = store
    }

    public func snapshot() -> PowerSnapshot {
        let battery = LinuxSystem.battery()
        return PowerSnapshot(
            sleepDisabled: Keeper.running(in: store) != nil,
            lidClosed: LinuxSystem.logind("LidClosed"),
            externalDisplay: LinuxSystem.logind("Docked"),
            onBattery: battery.onBattery,
            batteryPercent: battery.percent,
            thermal: .nominal
        )
    }

    public func setSleepDisabled(_ disabled: Bool) throws {
        if disabled { try Keeper.start(in: store) } else { Keeper.stop(in: store) }
    }

    /// logind refuses to suspend while our own block lock exists, so suspend after the keeper exits.
    public func sleepNow() {
        LinuxSystem.suspend(after: Keeper.running(in: store))
    }
}

public enum Keeper {
    static let who = "NonSleep"
    static let what = "handle-lid-switch:sleep"

    static func pidFile(_ store: Store) -> URL { store.directory.appendingPathComponent("keeper.pid") }
    static func logFile(_ store: Store) -> URL { store.directory.appendingPathComponent("keeper.log") }

    /// PID of the live keeper, checked against its start time so a stale file can't match a reused PID.
    public static func running(in store: Store) -> pid_t? {
        let fields = ((try? String(contentsOf: pidFile(store), encoding: .utf8)) ?? "")
            .split(whereSeparator: \.isWhitespace)
        guard fields.count == 2, let pid = pid_t(fields[0]), let start = UInt64(fields[1]),
              Processes.startTime(of: pid) == start
        else { return nil }
        return pid
    }

    static func start(in store: Store) throws {
        guard running(in: store) == nil else { return }
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: store.directory, withIntermediateDirectories: true)
        try? fileManager.removeItem(at: pidFile(store))
        _ = fileManager.createFile(atPath: logFile(store).path, contents: nil)
        let log = try FileHandle(forWritingTo: logFile(store))
        defer { try? log.close() }
        // setsid -f: a new session, so closing the terminal that ran a hook can't SIGHUP the keeper.
        try LinuxSystem.detach([
            "setsid", "-f", "systemd-inhibit", "--what=\(what)", "--who=\(who)",
            "--why=Keeping the machine awake for AI agents", "--mode=block", Integration.cliPath(), "keeper",
        ], output: log)
        for _ in 0..<60 {
            if running(in: store) != nil { return }
            usleep(50_000)
        }
        let detail = ((try? String(contentsOf: logFile(store), encoding: .utf8)) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        throw NonSleepError.inhibitFailed(detail.isEmpty ? "the keeper did not start" : detail)
    }

    static func stop(in store: Store) {
        // A keeper that decides to release itself exits right after its reconcile returns.
        guard let pid = running(in: store), pid != getpid() else { return }
        kill(pid, SIGTERM)
        for _ in 0..<40 where running(in: store) != nil { usleep(50_000) }
        if running(in: store) != nil { kill(pid, SIGKILL) }
        try? FileManager.default.removeItem(at: pidFile(store))
    }

    /// Body of `nonsleep keeper` (started by `start(in:)` under `systemd-inhibit`): staying alive holds
    /// the lock. Every 5 s it reconciles and exits once no live lease remains or a safety cut-out
    /// applies; every second it checks the lid and locks the session when it closes.
    public static func run(engine: NonSleep) -> Never {
        let store = engine.store
        let me = getpid()
        try? "\(me) \(Processes.startTime(of: me) ?? 0)".write(to: pidFile(store), atomically: true, encoding: .utf8)
        let lockHolder = getppid()
        var lidWasClosed = LinuxSystem.logind("LidClosed")
        var tick = 0

        func finish() -> Never {
            if running(in: store) == me { try? FileManager.default.removeItem(at: pidFile(store)) }
            exit(0)
        }

        while true {
            if getppid() != lockHolder { finish() }  // systemd-inhibit is gone, and with it the lock
            if tick % 5 == 0, let status = try? engine.reconcile(), status.leases.isEmpty || status.blockedBy != nil {
                finish()
            }
            let lidClosed = LinuxSystem.logind("LidClosed")
            if lidClosed, !lidWasClosed, ((try? engine.config()) ?? .defaults).lockOnLidClose, !LinuxSystem.logind("Docked") {
                LinuxSystem.lockSession()
            }
            lidWasClosed = lidClosed
            tick += 1
            sleep(1)
        }
    }
}

enum LinuxSystem {
    /// A boolean property of logind's Manager object (`LidClosed`, `Docked`); `false` if unavailable.
    static func logind(_ property: String) -> Bool {
        guard let result = try? Command.run("/usr/bin/env", [
            "busctl", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager", property,
        ]), result.status == 0 else { return false }
        return LinuxParse.busctlBool(result.stdout) ?? false
    }

    static func battery() -> (onBattery: Bool, percent: Int?) {
        let root = "/sys/class/power_supply"
        let names = (try? FileManager.default.contentsOfDirectory(atPath: root)) ?? []
        return LinuxParse.battery(names.map { name in
            func read(_ file: String) -> String? {
                let text = Proc.text("\(root)/\(name)/\(file)").trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            }
            return (type: read("type") ?? "", status: read("status"), capacity: read("capacity"))
        })
    }

    static func lockSession() {
        _ = try? Command.run("/usr/bin/env", ["loginctl", "lock-session"])
    }

    static func suspend(after keeper: pid_t?) {
        if let keeper {
            let script = "while kill -0 \(keeper) 2>/dev/null; do sleep 0.2; done; exec systemctl suspend"
            try? detach(["setsid", "-f", "sh", "-c", script], output: nil)
        } else {
            _ = try? Command.run("/usr/bin/env", ["systemctl", "suspend"])
        }
    }

    /// Runs a `setsid -f …` command and returns once it has forked off the detached child.
    static func detach(_ arguments: [String], output: FileHandle?) throws {
        _ = Command.wait(try Command.spawn("/usr/bin/env", arguments, output: output?.fileDescriptor))
    }
}
#endif
