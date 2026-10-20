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
        #expect(Policy.blocker(PowerSnapshot(thermal: .serious), minBatteryPercent: 20) != nil)
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
        #expect(Agents.matching(assertions, names: ["OMP agent", "caffeinate"]) == [
            "omp agent session · pid 2", "caffeinate command-line tool · pid 3",
        ])
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
    }
}
