#if canImport(Glibc)
import Glibc
#endif
import Foundation
import Testing
@testable import NonSleepKit

/// Records flag changes instead of calling `sudo pmset`.
final class FakePower: PowerControl, @unchecked Sendable {
    struct Denied: Error {}

    private let lock = NSLock()
    private var state: PowerSnapshot
    private(set) var sleepNowCalls = 0
    /// The real flag as last written, independent of what `snapshot()` reports.
    private(set) var flag = false
    /// `snapshot()` keeps reporting the initial flag (registry read lagging or wrong).
    var staleRead = false
    /// `setSleepDisabled` throws, like `sudo -n` without the sudoers rule.
    var denied = false

    init(_ state: PowerSnapshot = PowerSnapshot()) {
        self.state = state
        flag = state.sleepDisabled
    }

    func update(_ change: (inout PowerSnapshot) -> Void) { lock.withLock { change(&state) } }
    func snapshot() -> PowerSnapshot { lock.withLock { state } }
    func sleepNow() { lock.withLock { sleepNowCalls += 1 } }
    func setSleepDisabled(_ disabled: Bool) throws {
        try lock.withLock {
            if denied { throw Denied() }
            flag = disabled
            if !staleRead { state.sleepDisabled = disabled }
        }
    }
}

func makeEngine(_ power: FakePower) -> NonSleep {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("nonsleep-\(UUID().uuidString)")
    return NonSleep(store: Store(directory: directory), power: power)
}

@Suite struct LeaseLifetime {
    let now = Date(timeIntervalSince1970: 1_000_000)

    @Test func detachedLeaseLivesUntilExpiry() {
        let lease = Lease(id: "m", reason: "", ownerPID: nil, ownerStart: nil, bootTime: 7, expiresAt: now + 60)
        #expect(lease.isAlive(now: now, bootTime: 7, ownerStart: nil))
        #expect(!lease.isAlive(now: now + 60, bootTime: 7, ownerStart: nil))
    }

    @Test func leaseDiesOnReboot() {
        let lease = Lease(id: "m", reason: "", ownerPID: nil, ownerStart: nil, bootTime: 7, expiresAt: nil)
        #expect(!lease.isAlive(now: now, bootTime: 8, ownerStart: nil))
    }

    @Test func ownedLeaseDiesWithOwnerOrPIDReuse() {
        let lease = Lease(id: "a", reason: "", ownerPID: 42, ownerStart: 100, bootTime: 7, expiresAt: nil)
        #expect(lease.isAlive(now: now, bootTime: 7, ownerStart: 100))
        #expect(!lease.isAlive(now: now, bootTime: 7, ownerStart: nil))
        #expect(!lease.isAlive(now: now, bootTime: 7, ownerStart: 101))
    }
}

@Suite struct Reconcile {
    @Test func flagFollowsLeases() throws {
        let power = FakePower()
        let engine = makeEngine(power)
        #expect(try engine.hold(.owned(id: "a", reason: "test")).power.sleepDisabled)
        #expect(try engine.hold(.detached(id: "b", reason: "test", expiresAt: nil)).power.sleepDisabled)
        #expect(try engine.release(id: "a").power.sleepDisabled)
        #expect(try !engine.release(id: "b").power.sleepDisabled)
    }

    @Test func expiredAndDeadOwnerLeasesAreSwept() throws {
        let power = FakePower()
        let engine = makeEngine(power)
        let boot = Processes.bootTime()
        try engine.store.save(Lease(id: "old", reason: "", ownerPID: nil, ownerStart: nil, bootTime: boot, expiresAt: Date() - 1))
        try engine.store.save(Lease(id: "gone", reason: "", ownerPID: getpid(), ownerStart: 1, bootTime: boot, expiresAt: nil))
        let status = try engine.reconcile()
        #expect(status.leases.isEmpty)
        #expect(engine.store.leases().isEmpty)
    }

    @Test func lowBatteryOverridesLeasesAndSleepsClosedLid() throws {
        let power = FakePower(PowerSnapshot(lidClosed: true, onBattery: true, batteryPercent: 50))
        let engine = makeEngine(power)
        #expect(try engine.hold(.owned(id: "a", reason: "")).power.sleepDisabled)

        power.update { $0.batteryPercent = 19 }
        let status = try engine.reconcile()
        #expect(!status.power.sleepDisabled)
        #expect(status.blockedBy != nil)
        #expect(status.leases.count == 1)
        #expect(power.sleepNowCalls == 1)

        power.update { $0.onBattery = false }
        #expect(try engine.reconcile().power.sleepDisabled)
    }

    @Test func doesNotSleepWhenExternalDisplayIsAttached() throws {
        let power = FakePower(PowerSnapshot(lidClosed: true, externalDisplay: true))
        let engine = makeEngine(power)
        try engine.hold(.owned(id: "a", reason: ""))
        try engine.release(id: "a")
        #expect(power.sleepNowCalls == 0)
    }

    @Test func leavesFlagSetByAnotherToolAlone() throws {
        let power = FakePower(PowerSnapshot(sleepDisabled: true))
        let engine = makeEngine(power)
        #expect(try engine.reconcile().setByOtherTool)
        try engine.hold(.owned(id: "a", reason: ""))
        let status = try engine.release(id: "a")
        #expect(status.power.sleepDisabled)
        #expect(status.setByOtherTool)
    }

    @Test func hotMachineIsBlocked() {
        let policy = ThermalPolicy(config: .defaults)
        #expect(policy.isTooHot(PowerSnapshot(thermal: .serious)))
        #expect(!policy.isTooHot(PowerSnapshot(thermal: .fair)))
        #expect(Policy.blocker(
            PowerSnapshot(thermal: .serious), minBatteryPercent: 20,
            thermal: .tripped(.serious, backpack: false)
        ) != nil)
        #expect(Policy.blocker(PowerSnapshot(thermal: .fair), minBatteryPercent: 20) == nil)
        #expect(Policy.blocker(PowerSnapshot(onBattery: false, batteryPercent: 5), minBatteryPercent: 20) == nil)
    }

    @Test func clearsFlagEvenWhenTheReadIsStale() throws {
        let power = FakePower()
        power.staleRead = true
        let engine = makeEngine(power)
        try engine.hold(.owned(id: "a", reason: ""))
        #expect(power.flag)
        try engine.release(id: "a")
        #expect(!power.flag)
    }

    @Test func deniedPmsetLeavesNoLeaseAndNoClaim() throws {
        let power = FakePower()
        power.denied = true
        let engine = makeEngine(power)
        #expect(throws: FakePower.Denied.self) { try engine.hold(.owned(id: "a", reason: "")) }
        #expect(engine.store.leases().isEmpty)
        #expect(!engine.store.ownsFlag)
        _ = try engine.reconcile()  // must not keep failing afterwards
    }

    @Test func sleepNowReleasesEverythingAndSleepsEvenWithTheLidOpen() throws {
        let power = FakePower()
        let engine = makeEngine(power)
        try engine.hold(.detached(id: "m", reason: "", expiresAt: nil))
        let status = try engine.sleepNow()
        #expect(status.leases.isEmpty)
        #expect(!power.flag)
        #expect(power.sleepNowCalls == 1)
    }

    @Test func offClearsEverythingAndRetriesAFailedClear() throws {
        let power = FakePower()
        let engine = makeEngine(power)
        try engine.hold(.owned(id: "a", reason: ""))
        try engine.hold(.detached(id: "b", reason: "", expiresAt: nil))

        power.denied = true
        #expect(throws: FakePower.Denied.self) { try engine.releaseAll() }
        #expect(engine.store.leases().isEmpty)
        #expect(engine.store.ownsFlag, "the claim must survive so the reaper retries")
        #expect(power.flag)

        power.denied = false
        #expect(try !engine.reconcile().power.sleepDisabled)
        #expect(!power.flag)
        #expect(!engine.store.ownsFlag)
    }
}

@Suite struct Matching {
    @Test func processNameMatchesExecutableOrInterpretedScript() {
        #expect(Processes.arguments(["claude"], match: "claude"))
        #expect(Processes.arguments(["bun", "/Users/me/.bun/bin/omp", "--resume"], match: "omp"))
        #expect(!Processes.arguments(["/Applications/Claude.app/Contents/MacOS/Claude Helper"], match: "claude"))
        #expect(!Processes.arguments(["bun", "run", "omp"], match: "omp"))
    }

    @Test func assertionsMatchBySubstringOncePerProcess() {
        let assertions = [
            PowerAssertion(pid: 2, name: "omp agent session"),
            PowerAssertion(pid: 2, name: "omp agent session"),
            PowerAssertion(pid: 3, name: "caffeinate command-line tool"),
            PowerAssertion(pid: 4, name: "Electron"),
        ]
        #expect(Agents.matching(assertions, names: ["OMP agent", "caffeinate"]).map(\.label) == [
            "omp agent session · pid 2", "caffeinate command-line tool · pid 3",
        ])
        #expect(Agents.matching(assertions, names: ["omp"]).map(\.source) == [.assertion])
    }

    @Test func graceKeepsHoldingBetweenTurns() {
        var grace = Grace(seconds: 120)
        let start = Date()
        let observed = [(false, 0.0), (true, 0), (false, 119), (false, 120)].map { active, offset in
            grace.update(active: active, now: start + offset)
        }
        #expect(observed == [false, true, true, false])
    }

    @Test func durationFormatRoundTrips() {
        for seconds: TimeInterval in [30, 120, 90, 3600, 3900, 5430] {
            #expect(Duration.parse(Duration.format(seconds)) == seconds)
        }
        #expect(Duration.format(0) == "0s")
    }

    @Test func durations() {
        #expect(Duration.parse("90") == 5400)
        #expect(Duration.parse("3h") == 10800)
        #expect(Duration.parse("1h30m") == 5400)
        #expect(Duration.parse("45s") == 45)
        #expect(Duration.parse("3x") == nil)
        #expect(Duration.parse("h") == nil)
        #expect(Duration.parse("2h5") == nil)
        #expect(Duration.parse("inf") == nil)
    }

    @Test func partialConfigKeepsDefaults() throws {
        let config = try JSONDecoder().decode(Config.self, from: Data(#"{"processNames":["claude"]}"#.utf8))
        #expect(config.processNames == ["claude"])
        #expect(config.assertionNames == Config.defaults.assertionNames)
    }
}

@Suite struct JSONStatus {
    let now = Date(timeIntervalSince1970: 1_700_000_000)

    func report(_ status: Status, agents: [AgentActivity] = [], platform: String? = nil) -> StatusReport {
        StatusReport(status, agents: agents, thermalRetryLimit: 3, platform: platform, now: now)
    }

    /// `mode` is what a tray icon switches on, so it must follow the same precedence as the
    /// headline: a cut-out outranks a foreign flag, which outranks "we hold it".
    @Test func modeFollowsHeadlinePrecedence() {
        let held = PowerSnapshot(sleepDisabled: true)
        #expect(report(Status(power: held, leases: [], blockedBy: nil, setByOtherTool: false)).mode == .awake)
        #expect(report(Status(power: PowerSnapshot(), leases: [], blockedBy: nil, setByOtherTool: false)).mode == .normal)
        #expect(report(Status(power: held, leases: [], blockedBy: nil, setByOtherTool: true)).mode == .foreign)
        #expect(report(Status(power: held, leases: [], blockedBy: "battery 9% < 20%", setByOtherTool: true)).mode == .suspended)
    }

    @Test func reportRoundTripsThroughJSON() throws {
        let status = Status(
            power: PowerSnapshot(sleepDisabled: true, lidClosed: true, onBattery: true, batteryPercent: 41, thermal: .fair),
            leases: [
                Lease.detached(id: "manual", reason: "manual until 16:20", expiresAt: now + 600),
                Lease(id: "run", reason: "run: swift test", ownerPID: 42, ownerStart: 9, bootTime: 7, expiresAt: nil),
            ],
            blockedBy: nil,
            setByOtherTool: false,
            thermalGuard: ThermalGuard(trips: 2, resumes: 1, lockedOut: true)
        )
        let macOriginal = report(status, agents: [AgentActivity(name: "claude", pid: 7, source: .process)], platform: "macos")
        let macDecoded = try StatusReport.decode(macOriginal.json())

        #expect(macDecoded == macOriginal)
        #expect(macDecoded.schema == 1)
        #expect(macDecoded.leases.map(\.ownerPID) == [nil, 42])
        #expect(macDecoded.leases[0].expiresAt == now + 600)
        #expect(macDecoded.agents == [AgentActivity(name: "claude", pid: 7, source: .process)])
        #expect(macDecoded.thermalGuard == StatusReport.ThermalGuardInfo(trips: 2, resumes: 1, retryLimit: 3, lockedOut: true))
        #expect(macDecoded.power.batteryPercent == 41)
        #expect(macDecoded.power.thermal == .fair)

        let linuxOriginal = report(status, agents: [AgentActivity(name: "claude", pid: 7, source: .process)], platform: "linux")
        let linuxDecoded = try StatusReport.decode(linuxOriginal.json())
        #expect(linuxDecoded == linuxOriginal)
        #expect(linuxDecoded.power.thermal == nil)
    }
    /// Frontends poll this; the keys and the enumerated values are the contract, not the prose.
    @Test func jsonUsesStableKeysAndISODates() throws {
        let text = report(Status(power: PowerSnapshot(), leases: [], blockedBy: nil, setByOtherTool: false)).json()
        let object = try #require(try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        #expect(Set(object.keys) == [
            "schema", "version", "platform", "generatedAt", "mode", "headline",
            "power", "leases", "agents", "thermalGuard",
        ])
        #expect(object["generatedAt"] as? String == "2023-11-14T22:13:20Z")
        #expect(object["mode"] as? String == "normal")
        #expect(["macos", "linux"].contains(object["platform"] as? String ?? ""))
    }

    @Test func linuxOmitsThermalState() throws {
        let status = Status(power: PowerSnapshot(thermal: .fair), leases: [], blockedBy: nil, setByOtherTool: false)
        let linuxReport = StatusReport(status, agents: [], thermalRetryLimit: 3, platform: "linux", now: now)
        #expect(linuxReport.platform == "linux")
        #expect(linuxReport.power.thermal == nil)

        let decoded = try StatusReport.decode(linuxReport.json())
        #expect(decoded.power.thermal == nil)

        // The JSON itself must either omit "thermal" or encode it as null, never "nominal".
        let raw = try #require(try JSONSerialization.jsonObject(with: Data(linuxReport.json().utf8)) as? [String: Any])
        let power = try #require(raw["power"] as? [String: Any])
        #expect(power["thermal"] == nil || power["thermal"] is NSNull)
    }
}

@Suite struct HookIntegrations {
    /// Configs as other tools (here: Orca-style hooks) leave them; NonSleep must not disturb them.
    func existing(_ agent: HookAgent) -> [String: Any] {
        switch agent {
        case .claude:
            ["env": ["A": "1"], "hooks": ["Stop": [["hooks": [["type": "command", "command": "orca-hook.sh"]]]]]]
        case .cursor:
            ["version": 1, "hooks": ["stop": [["command": "orca-hook.sh", "timeout": 10]]]]
        case .antigravity:
            ["linter": ["PostToolUse": [["matcher": "run_command", "hooks": [["command": "lint.sh"]]]]]]
        case .codex:
            ["UserPromptSubmit": [["hooks": [["type": "command", "command": "lint.sh"]]]]]
        }
    }

    func text(_ object: [String: Any]) -> String {
        String(decoding: try! JSONSerialization.data(withJSONObject: object, options: .sortedKeys), as: UTF8.self)
    }

    @Test(arguments: HookAgent.allCases)
    func installIsIdempotentAndRemoveRestoresTheOriginal(agent: HookAgent) {
        let original = existing(agent)
        let first = Integration.installing(agent, cli: "/Old/nonsleep", into: original)
        let second = Integration.installing(agent, cli: "/New/nonsleep", into: first)
        #expect(!Integration.isInstalled(agent, in: original))
        #expect(Integration.isInstalled(agent, in: second))
        #expect(text(second).contains("orca-hook.sh") || text(second).contains("lint.sh"))
        #expect(!text(second).contains("/Old/nonsleep"), "reinstall must replace, not duplicate")
        #expect(text(Integration.removing(agent, from: second)) == text(original))
    }

    @Test func hookCommandSurvivesAnApostropheInTheCLIPath() {
        let command = Integration.command(cli: "/Users/o'brien/Applications/NonSleep.app/Contents/MacOS/nonsleep", agent: .claude, event: "Stop")
        #expect(command == "'/Users/o'\\''brien/Applications/NonSleep.app/Contents/MacOS/nonsleep' hook claude Stop")
        let installed = Integration.installing(.claude, cli: "/Users/o'brien/nonsleep", into: existing(.claude))
        #expect(Integration.isInstalled(.claude, in: installed))
    }

    @Test func claudeTurnIsHeldUntilStopAndPrintsNothing() {
        let payload = Data(#"{"session_id":"abc123def456789","cwd":"/Users/me/proj"}"#.utf8)
        let start = Hooks.decide(agent: .claude, event: "UserPromptSubmit", payload: payload)
        #expect(start.action == .working)
        #expect(start.response.isEmpty, "UserPromptSubmit stdout would be fed to the model")
        #expect(start.reason == "Claude Code · proj")
        let stop = Hooks.decide(agent: .claude, event: "Stop", payload: payload)
        #expect(stop.action == .finished)
        #expect(stop.leaseID == start.leaseID)
        #expect(Hooks.decide(agent: .claude, event: "PreCompact", payload: payload).action == nil)
    }

    @Test func cursorGetsTheResponsesItRequires() {
        let payload = Data(#"{"conversation_id":"c1","workspace_roots":["/w/app"]}"#.utf8)
        let submit = Hooks.decide(agent: .cursor, event: "beforeSubmitPrompt", payload: payload)
        #expect(submit.action == .working)
        #expect(submit.response == #"{"continue":true}"#)
        #expect(Hooks.decide(agent: .cursor, event: "stop", payload: payload).action == .finished)
    }

    @Test func antigravityKeepsHoldingWhileBackgroundTasksRun() {
        let busy = Hooks.decide(agent: .antigravity, event: "Stop", payload: Data(#"{"conversationId":"x","fullyIdle":false}"#.utf8))
        let idle = Hooks.decide(agent: .antigravity, event: "Stop", payload: Data(#"{"conversationId":"x","fullyIdle":true}"#.utf8))
        #expect(busy.action == .working)
        #expect(idle.action == .finished)
        #expect(idle.response == #"{"decision":"stop"}"#, "Stop requires a decision; anything but continue lets it stop")
    }
    @Test func codexTurnIsHeldUntilStop() {
        let payload = Data(#"{"session_id":"codex-123456","cwd":"/Users/me/app"}"#.utf8)
        let start = Hooks.decide(agent: .codex, event: "UserPromptSubmit", payload: payload)
        #expect(start.action == .working)
        #expect(start.leaseID == "codex-codex-123456")
        #expect(start.reason == "Codex · app")
        #expect(start.response == "{}")

        let stop = Hooks.decide(agent: .codex, event: "Stop", payload: payload)
        #expect(stop.action == .finished)
        #expect(stop.response == "{}")
    }
}

#if os(macOS)
@Suite struct SetupRules {
    @Test func sudoersRuleAllowsExactlyTheTwoCommands() {
        #expect(Setup.sudoersRule(user: "duy.tran-2")
            == "duy.tran-2 ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1\n")
    }

    @Test(arguments: ["", "-h", "a b", "a,ALL", "root\nALL", "x ALL=(ALL) ALL #"])
    func sudoersRuleRejectsNamesThatCouldInject(user: String) {
        #expect(Setup.sudoersRule(user: user) == nil)
    }
}
#endif

@Suite struct LinuxFormats {
    @Test func procStatSurvivesParenthesesAndSpacesInTheCommandName() {
        let line = "42 (my (weird) app) S 7 42 42 0 -1 4194560 100 0 0 0 1 2 0 0 20 0 1 0 98765 1000 12 0"
        let parsed = LinuxParse.stat(line)
        #expect(parsed?.parent == 7)
        #expect(parsed?.start == 98765)
        #expect(LinuxParse.stat("garbage") == nil)
    }

    @Test func procFiles() {
        #expect(LinuxParse.bootTime("cpu 1 2 3\nbtime 1700000000\nprocesses 9\n") == 1_700_000_000)
        #expect(LinuxParse.cmdline(Data("bun\0/home/me/.bun/bin/omp\0--resume\0".utf8)) == ["bun", "/home/me/.bun/bin/omp", "--resume"])
        #expect(LinuxParse.cmdline(Data()) == [])
    }

    @Test func logindReplies() {
        #expect(LinuxParse.busctlBool("b true\n") == true)
        #expect(LinuxParse.busctlBool("b false") == false)
        #expect(LinuxParse.busctlBool("") == nil)
        let json = #"{"type":"a(ssssuu)","data":[[["idle","omp","omp agent session","block",1000,4242],["handle-lid-switch:sleep","NonSleep","Keeping the machine awake","block",1000,77]]]}"#
        #expect(LinuxParse.inhibitors(json) == [
            .init(what: "idle", who: "omp", why: "omp agent session", mode: "block", pid: 4242),
            .init(what: "handle-lid-switch:sleep", who: "NonSleep", why: "Keeping the machine awake", mode: "block", pid: 77),
        ])
        #expect(LinuxParse.inhibitors("not json").isEmpty)
    }

    @Test func batteryFromPowerSupplies() {
        let onBattery = LinuxParse.battery([("Mains", nil, nil), ("Battery", "Discharging", "45")])
        #expect(onBattery.onBattery && onBattery.percent == 45)
        #expect(!LinuxParse.battery([("Battery", "Charging", "80")]).onBattery)
        let desktop = LinuxParse.battery([("Mains", nil, nil)])
        #expect(!desktop.onBattery && desktop.percent == nil)
        let withMouse = LinuxParse.battery([
            (name: "hidpp_battery_0", type: "Battery", status: "Discharging", capacity: "90", scope: "Device"),
            (name: "BAT0", type: "Battery", status: "Discharging", capacity: "15", scope: "System"),
        ])
        #expect(withMouse.onBattery && withMouse.percent == 15)
    }
}

@Suite struct ExtendedFeatures {
    /// Every bound that stops `history.json` from growing without limit.
    func temporaryStore(maxEntries: Int = 50, retentionDays: Int = 30) -> (HistoryStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = HistoryStore(
            fileURL: directory.appendingPathComponent("history.json"),
            maxEntries: maxEntries, retentionDays: retentionDays
        )
        return (store, directory)
    }

    @Test func historyKeepsNewestEntriesOnly() throws {
        let (store, directory) = temporaryStore(maxEntries: 2)
        defer { try? FileManager.default.removeItem(at: directory) }
        let start = Date()

        for index in 1...5 {
            let from = start.addingTimeInterval(Double(index) * 600)
            #expect(try store.record(
                startedAt: from, endedAt: from.addingTimeInterval(300), reason: "session \(index)",
                startBattery: 90, endBattery: 88, peakThermal: "nominal", now: from
            ))
        }

        let kept = store.load(now: start.addingTimeInterval(3000))
        #expect(kept.map(\.reason) == ["session 5", "session 4"])
        #expect(kept[0].startBatteryPercent == 90 && kept[0].endBatteryPercent == 88)

        try store.clear()
        #expect(store.load().isEmpty)
        #expect(store.fileSize == 0)
    }

    @Test func historyDropsEntriesPastTheRetentionWindow() throws {
        let (store, directory) = temporaryStore(retentionDays: 7)
        defer { try? FileManager.default.removeItem(at: directory) }
        let now = Date()
        let old = now.addingTimeInterval(-10 * 86_400)
        let recent = now.addingTimeInterval(-2 * 86_400)

        try store.save([
            SessionRecord(startedAt: old, endedAt: old.addingTimeInterval(600), reason: "old"),
            SessionRecord(startedAt: recent, endedAt: recent.addingTimeInterval(600), reason: "recent"),
        ], now: now)

        #expect(store.load(now: now).map(\.reason) == ["recent"])
    }

    @Test func historyRejectsUnboundedReasonsAndChurn() throws {
        let (store, directory) = temporaryStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let start = Date()

        // A lease reason is attacker-shaped input: an MCP caller passes arbitrary text.
        let huge = String(repeating: "x", count: 10_000)
        #expect(try store.record(
            startedAt: start, endedAt: start.addingTimeInterval(600), reason: huge,
            startBattery: nil, endBattery: nil, peakThermal: "nominal", now: start
        ))
        let stored = store.load(now: start)[0].reason
        #expect(stored.count == SessionRecord.maxReasonLength)
        #expect(stored.hasSuffix("…"))

        // A reconcile that flips the flag twice is not a session.
        #expect(try store.record(
            startedAt: start, endedAt: start.addingTimeInterval(1), reason: "blink",
            startBattery: nil, endBattery: nil, peakThermal: "nominal", now: start
        ) == false)
        #expect(store.load(now: start).count == 1)
    }

    @Test func historyDiscardsAnOversizedOrCorruptFile() throws {
        let (store, directory) = temporaryStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        try Data(repeating: 0x41, count: HistoryStore.maxFileBytes + 1).write(to: store.fileURL)
        #expect(store.load().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: store.fileURL.path))

        try Data("not json".utf8).write(to: store.fileURL)
        #expect(store.load().isEmpty)
    }

    @Test func historyOffWritesNothing() throws {
        let (store, directory) = temporaryStore(maxEntries: 0)
        defer { try? FileManager.default.removeItem(at: directory) }
        let start = Date()

        store.openSession(at: start, reason: "agent turn", battery: 80, thermal: .nominal)
        #expect(try store.record(
            startedAt: start, endedAt: start.addingTimeInterval(600), reason: "agent turn",
            startBattery: 80, endBattery: 78, peakThermal: "nominal", now: start
        ) == false)
        #expect(store.fileSize == 0)
        #expect(!FileManager.default.fileExists(atPath: store.markerURL.path))
    }

    @Test func sessionRecordsThePeakThermalNotTheFinalOne() throws {
        let (store, directory) = temporaryStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let start = Date()

        store.openSession(at: start, reason: "long build", battery: 92, thermal: .nominal)
        store.observe(thermal: .serious)
        store.observe(thermal: .fair)  // cooled down: the peak must not drop
        #expect(store.closeSession(at: start.addingTimeInterval(1800), battery: 71, thermal: .nominal))

        let records = store.load(now: start.addingTimeInterval(1800))
        #expect(records.count == 1)
        #expect(records[0].peakThermalState == "serious")
        #expect(records[0].startBatteryPercent == 92 && records[0].endBatteryPercent == 71)
        #expect(records[0].duration == 1800)
        // The open-session marker is consumed, so a second close records nothing.
        #expect(store.closeSession(at: start.addingTimeInterval(3600), battery: 60, thermal: .nominal) == false)
        #expect(store.load(now: start.addingTimeInterval(3600)).count == 1)
    }

    @Test func backpackCeilingIsStricterThanTheDeskCeiling() {
        var config = Config.defaults
        // Enclosed in a backpack: lid closed, on battery, no external display.
        let enclosed = PowerSnapshot(lidClosed: true, externalDisplay: false, onBattery: true, thermal: .fair)
        #expect(ThermalPolicy(config: config).isTooHot(enclosed))
        // With backpack protection off, `fair` is below the plain limit.
        config.backpackProtection = false
        #expect(!ThermalPolicy(config: config).isTooHot(enclosed))
        // An external display means it is on a desk, not in a bag.
        config.backpackProtection = true
        let deskMode = PowerSnapshot(lidClosed: true, externalDisplay: true, onBattery: true, thermal: .fair)
        #expect(!ThermalPolicy(config: config).isTooHot(deskMode))
        // A user who runs hot can stop at `fair` everywhere.
        config.thermalLimit = .fair
        #expect(ThermalPolicy(config: config).isTooHot(deskMode))
    }

    @Test func configExtendedFields() throws {
        let json = """
        {
            "soundEnabled": true,
            "soundPath": "/System/Library/Sounds/Glass.aiff",
            "backpackProtection": false
        }
        """
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        #expect(config.soundEnabled == true)
        #expect(config.soundPath == "/System/Library/Sounds/Glass.aiff")
        #expect(config.backpackProtection == false)
        #expect(config.assertionNames == Config.defaults.assertionNames)
    }

    @Test func statusAndBlockersFollowTheConfiguredLanguage() {
        let awake = Status(
            power: PowerSnapshot(sleepDisabled: true), leases: [], blockedBy: nil,
            setByOtherTool: false, language: .vi
        )
        #expect(awake.headline == "Vẫn chạy khi gập nắp máy")

        let english = Status(
            power: PowerSnapshot(sleepDisabled: true), leases: [], blockedBy: nil,
            setByOtherTool: false, language: .en
        )
        #expect(english.headline == "Stays awake with the lid closed")

        let flat = PowerSnapshot(onBattery: true, batteryPercent: 5)
        #expect(Policy.blocker(flat, minBatteryPercent: 20, language: .vi) == "pin 5% < 20%")
        #expect(Policy.blocker(flat, minBatteryPercent: 20, language: .en) == "battery 5% < 20%")
    }

    @Test func unknownLanguageCodeKeepsTheRestOfTheConfig() throws {
        let config = try JSONDecoder().decode(
            Config.self, from: Data(#"{"language":"klingon","minBatteryPercent":35}"#.utf8)
        )
        #expect(config.language == .auto)
        #expect(config.minBatteryPercent == 35)

        let vietnamese = try JSONDecoder().decode(Config.self, from: Data(#"{"language":"vi"}"#.utf8))
        #expect(vietnamese.language == .vi)
        #expect(vietnamese.language.resolved == .vi)
    }
}

@Suite struct ThermalRetries {
    let start = Date(timeIntervalSince1970: 2_000_000)
    let policy = ThermalPolicy(
        limit: .serious, backpackLimit: .fair, backpackProtection: true,
        retryLimit: 3, cooldown: 180, minRun: 300
    )
    let hot = PowerSnapshot(thermal: .serious)
    let cool = PowerSnapshot(thermal: .nominal)

    @Test func heatTripsThenResumesAfterTheCooldown() {
        let (tripped, hotVerdict) = ThermalGuard.idle.step(power: hot, policy: policy, now: start)
        #expect(hotVerdict == .tripped(.serious, backpack: false))
        #expect(tripped.trips == 1)

        // Cool again, but the cooldown has not elapsed yet.
        let (waiting, coolingVerdict) = tripped.step(power: cool, policy: policy, now: start + 60)
        #expect(coolingVerdict == .cooling(remaining: 120, attempt: 1, limit: 3))
        #expect(waiting.resumes == 0)

        let (resumed, runVerdict) = waiting.step(power: cool, policy: policy, now: start + 180)
        #expect(runVerdict == .run)
        #expect(resumed.resumes == 1)
        #expect(resumed.trippedAt == nil)
    }

    @Test func staysTrippedWhileStillHotWithoutBurningRetries() {
        var state = ThermalGuard.idle
        for offset in stride(from: 0.0, through: 600.0, by: 60.0) {
            let (next, verdict) = state.step(power: hot, policy: policy, now: start + offset)
            #expect(verdict == .tripped(.serious, backpack: false))
            state = next
        }
        // One continuous overheat is one trip, and no resume was spent on it.
        #expect(state.trips == 1)
        #expect(state.resumes == 0)
    }

    @Test func givesUpAfterTheRetryBudgetIsSpent() {
        var state = ThermalGuard.idle
        var clock = start
        // Three cycles of: overheat, cool down past minRun, resume.
        for attempt in 1...3 {
            state = state.step(power: hot, policy: policy, now: clock).0
            clock += policy.cooldown
            let (resumed, verdict) = state.step(power: cool, policy: policy, now: clock)
            #expect(verdict == .run)
            #expect(resumed.resumes == attempt)
            state = resumed
            clock += policy.minRun + 1  // long enough that this run counts as healthy
        }
        let (locked, verdict) = state.step(power: hot, policy: policy, now: clock)
        #expect(verdict == .lockedOut(trips: 4))
        #expect(locked.lockedOut)
        // Cooling down no longer helps: the episode stays locked out.
        #expect(locked.step(power: cool, policy: policy, now: clock + 3600).1 == .lockedOut(trips: 4))
    }

    @Test func aResumedRunThatOverheatsImmediatelyLocksOutEarly() {
        var state = ThermalGuard.idle
        state = state.step(power: hot, policy: policy, now: start).0
        let resumed = state.step(power: cool, policy: policy, now: start + policy.cooldown).0
        #expect(resumed.resumes == 1)

        // Hot again only a minute into the resumed run, with retries still on the clock.
        let (locked, verdict) = resumed.step(
            power: hot, policy: policy, now: start + policy.cooldown + 60
        )
        #expect(verdict == .lockedOut(trips: 2))
        #expect(locked.lockedOut)
    }

    @Test func retryLimitZeroNeverResumesOnItsOwn() {
        let strict = ThermalPolicy(
            limit: .serious, backpackLimit: .fair, backpackProtection: true,
            retryLimit: 0, cooldown: 180, minRun: 300
        )
        let (locked, verdict) = ThermalGuard.idle.step(power: hot, policy: strict, now: start)
        #expect(verdict == .lockedOut(trips: 1))
        #expect(locked.step(power: cool, policy: strict, now: start + 3600).1 == .lockedOut(trips: 1))
    }

    @Test func engineBlocksWhileHotAndForgetsTheEpisodeWhenLeasesEnd() throws {
        let power = FakePower(PowerSnapshot(thermal: .serious))
        let engine = makeEngine(power)

        let blocked = try engine.hold(.owned(id: "a", reason: "build"))
        #expect(blocked.blockedBy != nil)
        #expect(!power.flag)
        #expect(blocked.thermalGuard.trips == 1)

        // Still hot: the lease is held but the flag stays off.
        power.update { $0.thermal = .nominal }
        let cooling = try engine.reconcile()
        #expect(cooling.blockedBy != nil)  // cooldown has not elapsed
        #expect(!power.flag)

        // Releasing every lease ends the episode, so the next run starts with a full budget.
        let idle = try engine.releaseAll()
        #expect(idle.thermalGuard.isIdle)
        #expect(engine.store.thermalGuard.isIdle)

        let running = try engine.hold(.owned(id: "b", reason: "build"))
        #expect(running.blockedBy == nil)
        #expect(power.flag)
    }
}

@Suite struct ReleaseFeedParsing {
    let fallback = URL(string: "https://example.invalid/releases")!

    @Test func newerVersionsAreOrderedNumericallyNotLexically() {
        #expect(ReleaseFeed.isNewer("0.4.0", than: "0.3.0"))
        #expect(ReleaseFeed.isNewer("0.10.0", than: "0.9.0"))  // not a string comparison
        #expect(ReleaseFeed.isNewer("1.0.0", than: "0.9.9"))
        #expect(ReleaseFeed.isNewer("v0.3.1", than: "0.3.0"))  // tag prefix is ignored
        #expect(!ReleaseFeed.isNewer("0.3.0", than: "0.3.0"))
        #expect(!ReleaseFeed.isNewer("0.2.9", than: "0.3.0"))
        #expect(ReleaseFeed.isNewer("0.4", than: "0.3.9"))     // missing components count as 0
    }

    @Test func aReleaseOutranksThePrereleaseOfTheSameNumber() {
        #expect(ReleaseFeed.isNewer("0.3.0", than: "0.3.0-beta.1"))
        #expect(!ReleaseFeed.isNewer("0.3.0-beta.1", than: "0.3.0"))
        #expect(ReleaseFeed.isNewer("0.3.0-beta.2", than: "0.3.0-beta.1"))
        #expect(!ReleaseFeed.isNewer("0.3.0-beta.1", than: "0.3.0-beta.1"))
    }

    @Test func parsesTheTagAndPageAndRejectsRubbish() {
        let body = Data(#"{"tag_name":"v0.4.0","html_url":"https://example.test/tag/v0.4.0"}"#.utf8)
        let release = ReleaseFeed.parse(body, fallbackPage: fallback)
        #expect(release?.version == "0.4.0")
        #expect(release?.page.absoluteString == "https://example.test/tag/v0.4.0")

        // A tag without a page link still works; the caller's fallback is used.
        let noPage = ReleaseFeed.parse(Data(#"{"tag_name":"0.4.0"}"#.utf8), fallbackPage: fallback)
        #expect(noPage?.page == fallback)

        #expect(ReleaseFeed.parse(Data("not json".utf8), fallbackPage: fallback) == nil)
        #expect(ReleaseFeed.parse(Data(#"{"tag_name":""}"#.utf8), fallbackPage: fallback) == nil)
        #expect(ReleaseFeed.parse(Data(), fallbackPage: fallback) == nil)
    }
}
