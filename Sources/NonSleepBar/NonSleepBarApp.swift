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
        Text(model.headline)
        if let facts = model.facts { Text(facts) }
        ForEach(model.status?.leases ?? []) { lease in
            Text("• " + lease.reason)
        }
        if !model.agents.isEmpty {
            Text("Agents: " + model.agents.joined(separator: ", "))
        }
        if let error = model.error {
            Text("⚠︎ " + error)
        }

        Divider()
        Toggle("Auto: while agents are working", isOn: $model.autoMode)
        Menu("Keep awake") {
            Button("For 1 hour") { model.keepAwake(for: 3600) }
            Button("For 3 hours") { model.keepAwake(for: 3 * 3600) }
            Button("For 8 hours") { model.keepAwake(for: 8 * 3600) }
            Button("Until turned off") { model.keepAwake(for: nil) }
        }
        Button("Turn off") { model.turnOff() }
            .disabled(model.status?.leases.isEmpty ?? true)
        Button("Sleep now") { model.sleepNow() }

        Divider()
        Button("Open NonSleep…", action: openWindow)
            .keyboardShortcut(",")
        Button("Quit NonSleep") { model.quit() }
            .keyboardShortcut("q")
    }
}
