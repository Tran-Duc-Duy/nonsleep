import AppKit
import NonSleepKit
import SwiftUI

@main
struct NonSleepBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra {
            BarMenu(model: delegate.model, openWindow: delegate.showWindow)
        } label: {
            MenuBarIcon(model: delegate.model)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) lazy var model = BarModel()
    private lazy var window = MainWindowController(model: model)

    func showWindow() {
        window.show()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // First launch or unfinished setup: show the window so it's clear what to do next.
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "launchedBefore") || !model.setup.ready {
            showWindow()
        }
        defaults.set(true, forKey: "launchedBefore")
    }

    /// Opening the app from Finder/Spotlight while it's already running.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow()
        return false
    }
}

struct MenuBarIcon: View {
    @ObservedObject var model: BarModel

    var body: some View {
        Image(systemName: model.symbol)
    }
}

struct BarMenu: View {
    @ObservedObject var model: BarModel
    let openWindow: () -> Void

    var body: some View {
        let language = model.config.language
        Text(model.headline)
        if let facts = model.facts { Text(facts) }
        ForEach(model.status?.leases ?? []) { lease in
            Text("• " + lease.reason)
        }
        if !model.agents.isEmpty {
            Text(L10n.agentsLabel(language) + ": " + model.agents.joined(separator: ", "))
        }
        if let error = model.error {
            Text("⚠︎ " + error)
        }

        Divider()
        Toggle(L10n.autoWhileAgentsWork(language), isOn: $model.autoMode)
        Menu(L10n.keepAwake(language)) {
            Button(L10n.forOneHour(language)) { model.keepAwake(for: 3600) }
            Button(L10n.forThreeHours(language)) { model.keepAwake(for: 3 * 3600) }
            Button(L10n.forEightHours(language)) { model.keepAwake(for: 8 * 3600) }
            Button(L10n.untilTurnedOff(language)) { model.keepAwake(for: nil) }
            Divider()
            Button(L10n.customDuration(language), action: openWindow)
        }
        Button(L10n.turnOff(language)) { model.turnOff() }
            .disabled(model.status?.leases.isEmpty ?? true)
        Button(L10n.sleepNow(language)) { model.sleepNow() }

        Divider()
        Button(L10n.openNonSleep(language), action: openWindow)
            .keyboardShortcut(",")
        Button(L10n.quitNonSleep(language)) { model.quit() }
            .keyboardShortcut("q")
    }
}
