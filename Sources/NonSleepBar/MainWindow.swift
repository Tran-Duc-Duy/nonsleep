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
    private var language: Language { model.config.language }

    var body: some View {
        Form {
            Section { header }
            Section(L10n.sectionKeepingAwake(language)) { leases }
            Section(L10n.sectionAgents(language)) { agents }
            Section(L10n.sectionIntegrations(language)) { integrations }
            Section(L10n.sectionSettings(language)) { settings }
            Section(L10n.sectionSetup(language)) { setup }
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
                Menu(L10n.keepAwake(language)) {
                    Button(L10n.forOneHour(language)) { model.keepAwake(for: 3600) }
                    Button(L10n.forThreeHours(language)) { model.keepAwake(for: 3 * 3600) }
                    Button(L10n.forEightHours(language)) { model.keepAwake(for: 8 * 3600) }
                    Button(L10n.untilTurnedOff(language)) { model.keepAwake(for: nil) }
                    Divider()
                    Button(L10n.customDuration(language)) { showCustomTimer.toggle() }
                        .help(L10n.customDurationHelp(language))
                }
                .fixedSize()
                Button(L10n.turnOff(language)) { model.turnOff() }
                    .disabled(model.status?.leases.isEmpty ?? true)
                Spacer()
                Button(L10n.sleepNow(language)) { model.sleepNow() }
                    .help(L10n.sleepNowHelp(language))
            }
            if showCustomTimer {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                        // `labelsHidden` is load-bearing: inside a grouped Form, a TextField's
                        // first argument becomes a leading label, so the hint would wrap to its
                        // left instead of sitting in the field. The hint belongs in `prompt`.
                        TextField("", text: $customDurationText, prompt: Text(L10n.customDurationExamples(language)))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 180)
                            .onSubmit { applyCustomTimer() }
                        Button(L10n.setTimer(language)) { applyCustomTimer() }
                            .disabled(Duration.parse(customDurationText) == nil)
                            .buttonStyle(.borderedProminent)
                        Button(L10n.cancel(language)) {
                            showCustomTimer = false
                            customDurationText = ""
                        }
                        Spacer(minLength: 0)
                    }
                    Text(L10n.customDurationPrompt(language))
                        .font(.caption).foregroundStyle(.secondary)
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
            Text(L10n.noLeases(language))
                .foregroundStyle(.secondary)
        }
        ForEach(leases) { lease in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lease.reason)
                    Text(lease.detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(L10n.release(language)) { model.release(id: lease.id) }
                    .help(L10n.releaseHelp(language))
            }
        }
    }

    @ViewBuilder private var agents: some View {
        if model.pausedUntilWake {
            Label(L10n.autoPausedUntilWake(language), systemImage: "pause.circle")
                .foregroundStyle(.secondary)
        }
        if model.agents.isEmpty {
            Text(L10n.noAgentWorking(language)).foregroundStyle(.secondary)
        }
        ForEach(model.agents, id: \.self) { agent in
            Label(agent, systemImage: "waveform.path.ecg")
        }
    }

    @ViewBuilder private var integrations: some View {
        SetupRow(ok: true, title: "omp", detail: L10n.ompBuiltIn(language))
        ForEach(HookAgent.allCases) { agent in
            Toggle(isOn: Binding(
                get: { model.integrations[agent] ?? false },
                set: { model.setIntegration(agent, enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(agent.displayName)
                    Text(L10n.hooksIn(agent.configURL.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))(language))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        Text(L10n.hooksExplanation(model.config.hookTimeoutMinutes)(language))
            .font(.caption).foregroundStyle(.secondary)
    }

    @ViewBuilder private var settings: some View {
        Picker(L10n.settingLanguage(language), selection: binding(\.language)) {
            ForEach(Language.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        Toggle(L10n.settingAuto(language), isOn: $model.autoMode)
        Toggle(L10n.settingLockOnLidClose(language), isOn: binding(\.lockOnLidClose))
        Text(L10n.settingLockOnLidCloseHelp(language))
            .font(.caption).foregroundStyle(.secondary)
        Toggle(L10n.settingSleepWhenDone(language), isOn: binding(\.sleepWhenDone))
        Text(L10n.settingSleepWhenDoneHelp(language))
            .font(.caption).foregroundStyle(.secondary)
        Toggle(L10n.settingSound(language), isOn: binding(\.soundEnabled))
        Text(L10n.settingSoundHelp(language))
            .font(.caption).foregroundStyle(.secondary)
        Toggle(L10n.settingBackpack(language), isOn: binding(\.backpackProtection))
        Text(L10n.settingBackpackHelp(language))
            .font(.caption).foregroundStyle(.secondary)
        Stepper(
            L10n.settingMinBattery(model.config.minBatteryPercent)(language),
            value: binding(\.minBatteryPercent), in: 0...50, step: 5
        )
        Text(L10n.settingMinBatteryHelp(language))
            .font(.caption).foregroundStyle(.secondary)
        Stepper(
            L10n.settingGrace(Duration.format(TimeInterval(model.config.graceSeconds)))(language),
            value: binding(\.graceSeconds), in: 0...900, step: 30
        )
        Text(L10n.settingGraceHelp(language))
            .font(.caption).foregroundStyle(.secondary)
        ListField(
            title: L10n.settingAssertions(language), prompt: L10n.settingAssertionsPrompt(language),
            values: model.config.assertionNames
        ) { names in model.updateConfig { $0.assertionNames = names } }
        ListField(
            title: L10n.settingProcesses(language), prompt: L10n.settingProcessesPrompt(language),
            values: model.config.processNames
        ) { names in model.updateConfig { $0.processNames = names } }
        Text(L10n.settingProcessesHelp(language))
            .font(.caption).foregroundStyle(.secondary)
        Toggle(L10n.settingLaunchAtLogin(language), isOn: Binding(get: { model.launchAtLogin }, set: { model.setLaunchAtLogin($0) }))
        HStack {
            Spacer()
            Button(L10n.openConfigFile(language)) { model.openConfigFile() }
        }
    }

    @ViewBuilder private var setup: some View {
        SetupRow(ok: model.setup.sudoers, title: L10n.setupSudoers(language), detail: Setup.sudoersPath)
        SetupRow(ok: model.setup.reaper, title: L10n.setupReaper(language), detail: L10n.setupReaperDetail(language))
        let delay = model.setup.screenLockDelay ?? "unknown"
        SetupRow(
            ok: delay == "immediate" || !model.config.lockOnLidClose,
            title: L10n.setupScreenLock(delay)(language),
            detail: L10n.setupScreenLockDetail(language)
        )
        if !model.setup.ready {
            HStack {
                Text(L10n.setupAdminPrompt(language))
                    .font(.callout)
                Spacer()
                Button(L10n.finishSetup(language)) { model.finishSetup() }
                    .disabled(model.settingUp)
            }
        }
        HStack {
            Text(L10n.setupOfflineNote(language))
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Link(L10n.securityPolicy(language), destination: URL(string: "https://github.com/Tran-Duc-Duy/nonsleep/blob/main/SECURITY.md")!)
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
