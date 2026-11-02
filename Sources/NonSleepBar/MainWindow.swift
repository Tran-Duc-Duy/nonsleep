import AppKit
import NonSleepKit
import SwiftUI

/// Owns the management window. AppKit-managed so it opens only on demand (menu, reopening the
/// app, first launch), never automatically at login. The app shows in the Dock while it's open.
@MainActor
final class MainWindowController: NSObject, NSWindowDelegate {
    private let model: BarModel
    private var window: NSWindow?

    init(model: BarModel) {
        self.model = model
    }

    func show() {
        model.refreshSetup()
        let window = window ?? makeWindow()
        self.window = window
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: MainWindow(model: model)))
        window.title = "NonSleep"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.setFrameAutosaveName("NonSleepMain")
        return window
    }
}

struct MainWindow: View {
    @ObservedObject var model: BarModel
    @State private var showCustomTimer = false
    @State private var customDurationText = ""
    var body: some View {
        Form {
            Section { header }
            Section("Keeping the Mac awake") { leases }
            Section("Agents") { agents }
            Section("Integrations") { integrations }
            Section("Settings") { settings }
            Section("Setup") { setup }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, idealWidth: 520, minHeight: 560, idealHeight: 760)
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Label(model.headline, systemImage: model.symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint)
                    if let facts = model.facts {
                        Text(facts).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            if let error = model.error {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            HStack(spacing: 8) {
                Menu("Keep awake") {
                    Button("For 1 hour") { model.keepAwake(for: 3600) }
                    Button("For 3 hours") { model.keepAwake(for: 3 * 3600) }
                    Button("For 8 hours") { model.keepAwake(for: 8 * 3600) }
                    Button("Until turned off") { model.keepAwake(for: nil) }
                    Divider()
                    Button("Custom duration…") { showCustomTimer.toggle() }
                }
                .fixedSize()
                Button("Custom…") { showCustomTimer.toggle() }
                    .help("Set a custom duration (e.g. 45m for YouTube, 2h for downloads)")
                Button("Turn off") { model.turnOff() }
                    .disabled(model.status?.leases.isEmpty ?? true)
                Spacer()
                Button("Sleep now") { model.sleepNow() }
                    .help("Releases everything and sleeps the Mac. The Apple-menu Sleep item can't while NonSleep holds it awake.")
            }
            if showCustomTimer {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundStyle(.secondary)
                    TextField("e.g. 30m, 45m, 2h, 1h30m (YouTube, downloads)", text: $customDurationText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 320)
                        .onSubmit { applyCustomTimer() }
                    Button("Set timer") { applyCustomTimer() }
                        .disabled(Duration.parse(customDurationText) == nil)
                        .buttonStyle(.borderedProminent)
                    Button("Cancel") {
                        showCustomTimer = false
                        customDurationText = ""
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }

    private func applyCustomTimer() {
        guard let seconds = Duration.parse(customDurationText) else { return }
        model.keepAwake(for: seconds)
        showCustomTimer = false
        customDurationText = ""
    }

    @ViewBuilder private var leases: some View {
        let leases = model.status?.leases ?? []
        if leases.isEmpty {
            Text("Nothing. Closing the lid sleeps the Mac as usual.")
                .foregroundStyle(.secondary)
        }
        ForEach(leases) { lease in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lease.reason)
                    Text(lease.detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Release") { model.release(id: lease.id) }
                    .help("A running `nonsleep run/wait/auto` takes its lease back on its next tick.")
            }
        }
    }

    @ViewBuilder private var agents: some View {
        if model.pausedUntilWake {
            Label("Auto mode is paused until you wake the screen.", systemImage: "pause.circle")
                .foregroundStyle(.secondary)
        }
        if model.agents.isEmpty {
            Text("No agent is working right now.").foregroundStyle(.secondary)
        }
        ForEach(model.agents, id: \.self) { agent in
            Label(agent, systemImage: "waveform.path.ecg")
        }
    }

    @ViewBuilder private var integrations: some View {
        SetupRow(ok: true, title: "omp", detail: "Built in: detected through its \"omp agent session\" power assertion")
        ForEach(HookAgent.allCases) { agent in
            Toggle(isOn: Binding(
                get: { model.integrations[agent] ?? false },
                set: { model.setIntegration(agent, enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.displayName)
                    Text("Hooks in \(agent.configURL.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        Text("Hooks hold the Mac awake during each turn and release it when the turn ends, or \(model.config.hookTimeoutMinutes) min after the agent's last activity. Other hooks in those files are left untouched; the first edit keeps a .nonsleep-backup copy.")
            .font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private var settings: some View {
        Toggle("Keep awake while agents work (Auto)", isOn: $model.autoMode)
        Toggle("Lock the screen when the lid closes", isOn: binding(\.lockOnLidClose))
        Text("Turns display off on lid close so macOS immediately locks your session.")
            .font(.caption).foregroundStyle(.secondary)
        Toggle("Sleep as soon as work is done, if the lid is closed", isOn: binding(\.sleepWhenDone))
        Text("When turns, scripts, or timers finish, automatically sleep if lid is closed.")
            .font(.caption).foregroundStyle(.secondary)
        Stepper(
            "Pause on battery below \(model.config.minBatteryPercent)%",
            value: binding(\.minBatteryPercent), in: 0...50, step: 5
        )
        Text("Safeguard: prevents running your battery down to zero in a backpack.")
            .font(.caption).foregroundStyle(.secondary)
        Stepper(
            "Keep holding \(Duration.format(TimeInterval(model.config.graceSeconds))) after agents finish",
            value: binding(\.graceSeconds), in: 0...900, step: 30
        )
        Text("Prevents sleep-wake thrashing between consecutive agent prompt turns.")
            .font(.caption).foregroundStyle(.secondary)
        ListField(title: "Power assertions", prompt: "e.g. omp agent session, caffeinate", values: model.config.assertionNames) {
            names in model.updateConfig { $0.assertionNames = names }
        }
        ListField(title: "Processes", prompt: "e.g. claude, codex, Orca", values: model.config.processNames) {
            names in model.updateConfig { $0.processNames = names }
        }
        Text("Keep awake while any listed process is running (e.g. codex, brew, rsync).")
            .font(.caption).foregroundStyle(.secondary)
        Toggle("Launch at login", isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
        HStack {
            Spacer()
            Button("Open config.json") { model.openConfigFile() }
        }
    }

    @ViewBuilder private var setup: some View {
        SetupRow(ok: model.setup.sudoers, title: "Passwordless pmset rule", detail: Setup.sudoersPath)
        SetupRow(ok: model.setup.reaper, title: "Reaper LaunchAgent", detail: "Clears crashed or expired leases every minute")
        let delay = model.setup.screenLockDelay ?? "unknown"
        SetupRow(
            ok: delay == "immediate" || !model.config.lockOnLidClose,
            title: "Screen lock delay: \(delay)",
            detail: "Locking on lid close needs System Settings › Lock Screen › Require password: Immediately"
        )
        if !model.setup.ready {
            HStack {
                Text("One administrator password, once: lets NonSleep toggle `pmset disablesleep` and clean up after crashes.")
                    .font(.callout)
                Spacer()
                Button("Finish setup…") { model.finishSetup() }
                    .disabled(model.settingUp)
            }
        }
        HStack {
            Text("NonSleep is 100% offline (zero network access, no telemetry, no root daemon). The sudoers rule allows only `pmset -a disablesleep 0|1`.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Link("Security Policy", destination: URL(string: "https://github.com/Tran-Duc-Duy/nonsleep/blob/main/SECURITY.md")!)
                .font(.caption)
        }
    }

    // MARK: Helpers

    private var tint: Color {
        if model.needsAttention { return .orange }
        return model.isAwake ? .green : .secondary
    }

    private func binding<Value: Equatable>(_ keyPath: WritableKeyPath<Config, Value>) -> Binding<Value> {
        Binding(
            get: { model.config[keyPath: keyPath] },
            set: { value in model.updateConfig { $0[keyPath: keyPath] = value } }
        )
    }
}

private struct SetupRow: View {
    let ok: Bool
    let title: String
    let detail: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ok ? .green : .orange)
        }
    }
}

/// Comma-separated list editor; saves on Return or when focus leaves the field.
private struct ListField: View {
    let title: String
    let prompt: String
    let values: [String]
    let commit: ([String]) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField(title, text: $text, prompt: Text(prompt))
            .focused($focused)
            .onAppear { text = values.joined(separator: ", ") }
            .onChange(of: values) { newValue in
                if !focused { text = newValue.joined(separator: ", ") }
            }
            .onChange(of: focused) { isFocused in
                if !isFocused { save() }
            }
            .onSubmit(save)
    }

    private func save() {
        commit(text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }
}
