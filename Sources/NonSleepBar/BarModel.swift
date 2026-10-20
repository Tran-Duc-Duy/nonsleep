import AppKit
import NonSleepKit
import os
import ServiceManagement

/// State and actions shared by the menu and the window. Engine calls stay on the main actor:
/// they take a short file lock and only shell out to `sudo pmset` when the state changes.
@MainActor
final class BarModel: ObservableObject {
    struct SetupState: Equatable {
        var sudoers: Bool
        var reaper: Bool
        var screenLockDelay: String?

        var ready: Bool { sudoers && reaper }

        static func check() -> SetupState {
            SetupState(
                sudoers: Setup.sudoersInstalled, reaper: Setup.reaperInstalled,
                screenLockDelay: Setup.screenLockDelay()
            )
        }
    }

    private static let autoID = "app-auto"
    private static let manualID = "app-manual"
    private static let log = Logger(subsystem: "dev.nonsleep.app", category: "app")

    @Published private(set) var status: Status?
    @Published private(set) var agents: [String] = []
    @Published private(set) var config = Config.defaults
    @Published private(set) var configError: String?
    @Published private(set) var actionError: String?
    @Published private(set) var setup = SetupState.check()
    /// Which hook integrations are present in each agent's user-level hooks file.
    @Published private(set) var integrations = BarModel.checkIntegrations()
    /// A "Finish setup…" run is waiting on the administrator dialog.
    @Published private(set) var settingUp = false
    @Published private(set) var launchAtLogin = SMAppService.mainApp.status == .enabled
    /// Set by "Sleep now" until the screens wake, so a dark wake can't re-arm lid-closed mode.
    @Published private(set) var pausedUntilWake = false
    @Published var autoMode: Bool {
        didSet {
            UserDefaults.standard.set(autoMode, forKey: "autoMode")
            tick()
        }
    }

    private let engine = NonSleep()
    private var grace: Grace?
    private var timer: Timer?
    private var lid: LidMonitor?
    /// Keeps App Nap from stretching the 10 s tick for this window-less app. Deliberately
    /// *allows* idle system sleep: NonSleep must not create a sleep assertion of its own.
    private let activity = ProcessInfo.processInfo.beginActivity(
        options: .userInitiatedAllowingIdleSystemSleep, reason: "Watching agent activity"
    )

    init() {
        autoMode = UserDefaults.standard.object(forKey: "autoMode") as? Bool ?? true
        NSApplication.shared.setActivationPolicy(.accessory)
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.releaseOwnLeases() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.screensDidWake() }
        }
        lid = LidMonitor { [weak self] closed in self?.lidChanged(closed: closed) }
        tick()
    }

    // MARK: Presentation

    var headline: String { status?.headline ?? "Starting…" }

    var isAwake: Bool { status?.power.sleepDisabled ?? false }

    var needsAttention: Bool { status?.blockedBy != nil || error != nil }

    var symbol: String {
        if needsAttention { return "exclamationmark.triangle" }
        return isAwake ? "waveform.path.ecg" : "moon.zzz"
    }

    var facts: String? {
        guard let power = status?.power else { return nil }
        var facts = [power.lidClosed ? "Lid closed" : "Lid open", power.onBattery ? "Battery" : "AC"]
        if let percent = power.batteryPercent { facts.append("\(percent)%") }
        if power.externalDisplay { facts.append("External display") }
        if power.thermal != .nominal { facts.append("Thermal \(power.thermal.rawValue)") }
        return facts.joined(separator: " · ")
    }

    var error: String? { actionError ?? configError }

    // MARK: Actions

    func keepAwake(for seconds: TimeInterval?) {
        let expiresAt = seconds.map { Date().addingTimeInterval($0) }
        let reason = expiresAt.map { "Manual until \($0.formatted(date: .omitted, time: .shortened))" }
            ?? "Manual until turned off"
        perform { try engine.hold(.owned(id: Self.manualID, reason: reason, expiresAt: expiresAt)) }
    }

    /// Releases everything, including leases held by the CLI, and stops auto mode.
    func turnOff() {
        autoMode = false
        perform { try engine.releaseAll() }
    }

    /// The Apple-menu Sleep item can't sleep the Mac while the flag is set; this can.
    func sleepNow() {
        pausedUntilWake = true
        grace = nil
        perform { try engine.sleepNow() }
    }

    func release(id: String) {
        perform { try engine.release(id: id) }
    }

    func updateConfig(_ change: (inout Config) -> Void) {
        var next = config
        change(&next)
        guard next != config else { return }
        do {
            try next.save(to: engine.store.configURL)
            config = next
            configError = nil
            tick()
        } catch {
            actionError = "Saving config: \(error.localizedDescription)"
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            actionError = "Launch at login: \(error.localizedDescription)"
        }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    func openConfigFile() {
        let url = engine.store.configURL
        if !FileManager.default.fileExists(atPath: url.path) {
            try? config.save(to: url)
        }
        NSWorkspace.shared.open(url)
    }

    func refreshSetup() {
        setup = .check()
        integrations = Self.checkIntegrations()
    }

    /// Installs the sudoers rule, reaper and CLI link. Runs off the main thread because the
    /// administrator dialog blocks until the user answers it.
    func finishSetup() {
        settingUp = true
        let cli = Integration.cliPath()
        Task.detached {
            let failure: String?
            do {
                try Setup.install(cli: cli)
                failure = nil
            } catch {
                failure = "\(error)"
            }
            await MainActor.run {
                self.settingUp = false
                self.actionError = failure
                self.refreshSetup()
                self.tick()
            }
        }
    }

    func setIntegration(_ agent: HookAgent, enabled: Bool) {
        do {
            if enabled { try Integration.install(agent) } else { try Integration.remove(agent) }
        } catch {
            actionError = "\(agent.displayName) hooks: \(error)"
        }
        integrations = Self.checkIntegrations()
    }

    private static func checkIntegrations() -> [HookAgent: Bool] {
        Dictionary(uniqueKeysWithValues: HookAgent.allCases.map { ($0, Integration.isInstalled($0)) })
    }

    func quit() {
        releaseOwnLeases()
        NSApplication.shared.terminate(nil)
    }

    // MARK: Engine loop

    private func releaseOwnLeases() {
        _ = try? engine.release(id: Self.autoID)
        _ = try? engine.release(id: Self.manualID)
    }

    private func screensDidWake() {
        pausedUntilWake = false
        tick()
    }

    private func lidChanged(closed: Bool) {
        Self.log.notice("lid \(closed ? "closed" : "opened", privacy: .public)")
        tick()
        guard closed, config.lockOnLidClose, let status, status.power.sleepDisabled, !status.power.externalDisplay
        else { return }
        Self.log.notice("lid closed while held awake: turning the display off to lock")
        SystemPower.displaySleepNow()
    }

    private func tick() {
        do {
            let loaded = try engine.config()
            if loaded != config { config = loaded }
            configError = nil
        } catch {
            configError = "\(error)"
        }
        agents = Agents.activity(config: config)

        guard autoMode, !pausedUntilWake else {
            grace = nil
            perform { try engine.release(id: Self.autoID) }
            return
        }
        var grace = self.grace ?? Grace(seconds: config.graceSeconds)
        grace.grace = TimeInterval(config.graceSeconds)
        let working = grace.update(active: !agents.isEmpty)
        self.grace = grace
        if working {
            let reason = agents.isEmpty ? "Auto: grace period" : "Auto: agents working"
            perform { try engine.hold(.owned(id: Self.autoID, reason: reason)) }
        } else {
            perform { try engine.release(id: Self.autoID) }
        }
    }

    private func perform(_ action: () throws -> Status) {
        let before = status?.headline
        do {
            status = try action()
            actionError = nil
        } catch {
            actionError = "\(error)"
            status = (try? engine.reconcile()) ?? status
        }
        if let after = status?.headline, after != before {
            Self.log.notice("state: \(after, privacy: .public)")
        }
    }
}
