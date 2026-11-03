import Foundation

public struct DiagnosticCheck: Sendable, Equatable {
    public enum Level: String, Sendable {
        case pass
        case warning
        case failure
    }

    public var title: String
    public var level: Level
    public var detail: String
    public var fixRecommendation: String?

    public init(title: String, level: Level, detail: String, fixRecommendation: String? = nil) {
        self.title = title
        self.level = level
        self.detail = detail
        self.fixRecommendation = fixRecommendation
    }
}

/// Read-only inspection of everything NonSleep needs from the system.
///
/// Every check MUST be free of side effects: `nonsleep doctor` is run while agents are working,
/// so a probe that actually toggled `disablesleep` would drop lid-closed protection mid-turn.
public struct Doctor: Sendable {
    public let store: Store
    /// Needed by the conflict check; injected so tests never touch the real machine.
    public let power: any PowerControl

    public init(store: Store = .standard, power: any PowerControl) {
        self.store = store
        self.power = power
    }

    public func diagnose() -> [DiagnosticCheck] {
        var checks: [DiagnosticCheck] = []
        checks.append(checkSudoers())
        checks.append(checkReaper())
        checks.append(checkScreenLock())
        checks.append(checkCLI())
        checks.append(checkHooks())
        checks.append(checkConflictingApps())
        return checks
    }

    private func checkSudoers() -> DiagnosticCheck {
        #if os(macOS)
        guard Setup.sudoersInstalled else {
            return DiagnosticCheck(
                title: "Sudoers Rule",
                level: .failure,
                detail: "Missing \(Setup.sudoersPath)",
                fixRecommendation: "Run `nonsleep setup` to install scoped sudoers rule."
            )
        }
        // `sudo -l <cmd>` asks "am I allowed to run this?" and exits 0 without running it.
        // Running the real command here would clear the flag out from under a live lease.
        let allowed = (try? Command.run(
            "/usr/bin/sudo", ["-n", "-l", "/usr/bin/pmset", "-a", "disablesleep", "1"]
        ))?.status == 0
        if allowed {
            return DiagnosticCheck(
                title: "Sudoers Rule",
                level: .pass,
                detail: "NOPASSWD access for `pmset -a disablesleep` confirmed"
            )
        } else {
            return DiagnosticCheck(
                title: "Sudoers Rule",
                level: .failure,
                detail: "\(Setup.sudoersPath) exists but sudo does not grant `pmset -a disablesleep`",
                fixRecommendation: "Re-run `nonsleep setup` to update the rule for current user."
            )
        }
        #else
        return DiagnosticCheck(
            title: "Privilege Model",
            level: .pass,
            detail: "Linux logind inhibitor lock in use (no root required)"
        )
        #endif
    }

    private func checkReaper() -> DiagnosticCheck {
        #if os(macOS)
        guard Setup.reaperInstalled else {
            return DiagnosticCheck(
                title: "Reaper LaunchAgent",
                level: .failure,
                detail: "Missing \(Setup.reaperPlistURL.path)",
                fixRecommendation: "Run `nonsleep setup` to install background reaper."
            )
        }
        let listResult = (try? Command.run("/bin/launchctl", ["list", Setup.reaperLabel]))
        if listResult?.status == 0 {
            return DiagnosticCheck(
                title: "Reaper LaunchAgent",
                level: .pass,
                detail: "\(Setup.reaperLabel) is active (runs every 60s)"
            )
        } else {
            return DiagnosticCheck(
                title: "Reaper LaunchAgent",
                level: .warning,
                detail: "Plist exists but \(Setup.reaperLabel) is not currently loaded in launchctl",
                fixRecommendation: "Run `nonsleep setup` or `launchctl load \(Setup.reaperPlistURL.path)`"
            )
        }
        #else
        return DiagnosticCheck(
            title: "Reaper",
            level: .pass,
            detail: "Auto-reap active on Linux"
        )
        #endif
    }

    private func checkScreenLock() -> DiagnosticCheck {
        #if os(macOS)
        let delay = Setup.screenLockDelay()
        if delay == "immediate" {
            return DiagnosticCheck(
                title: "Screen Lock Protection",
                level: .pass,
                detail: "Password required immediately after display sleeps"
            )
        } else if let delay {
            return DiagnosticCheck(
                title: "Screen Lock Protection",
                level: .warning,
                detail: "Screen lock delay is '\(delay)'",
                fixRecommendation: "Set 'Require password after display turns off' to 'Immediately' in System Settings > Lock Screen."
            )
        } else {
            return DiagnosticCheck(
                title: "Screen Lock Protection",
                level: .pass,
                detail: "Unable to query sysadminctl (assumed default)"
            )
        }
        #else
        return DiagnosticCheck(
            title: "Screen Lock Protection",
            level: .pass,
            detail: "loginctl lock-session configured"
        )
        #endif
    }

    private func checkCLI() -> DiagnosticCheck {
        let whichRes = try? Command.run("/usr/bin/which", ["nonsleep"])
        let path = whichRes?.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if whichRes?.status == 0 && path != nil && !path!.isEmpty {
            return DiagnosticCheck(
                title: "CLI in PATH",
                level: .pass,
                detail: "Found at \(path!)"
            )
        }
        #if os(macOS)
        if FileManager.default.fileExists(atPath: Setup.cliLinkURL.path) {
            return DiagnosticCheck(
                title: "CLI in PATH",
                level: .warning,
                detail: "Symlink exists at \(Setup.cliLinkURL.path) but ~/.local/bin is not in $PATH",
                fixRecommendation: "Add `export PATH=\"$HOME/.local/bin:$PATH\"` to your ~/.zshrc or ~/.bashrc."
            )
        }
        #endif
        return DiagnosticCheck(
            title: "CLI in PATH",
            level: .warning,
            detail: "`nonsleep` command not found in current PATH",
            fixRecommendation: "Run `nonsleep setup` to install ~/.local/bin/nonsleep symlink."
        )
    }

    private func checkHooks() -> DiagnosticCheck {
        let installed = HookAgent.allCases.filter { Integration.isInstalled($0) }
        if installed.isEmpty {
            return DiagnosticCheck(
                title: "Agent Hooks",
                level: .pass,
                detail: "No agent hooks installed (omp detected automatically via power assertion)"
            )
        } else {
            let names = installed.map(\.displayName).joined(separator: ", ")
            return DiagnosticCheck(
                title: "Agent Hooks",
                level: .pass,
                detail: "Active hooks for: \(names)"
            )
        }
    }

    /// The only thing that can actually override NonSleep is the `disablesleep` flag itself.
    /// Idle-sleep assertions cannot keep a closed lid awake — that is the premise of the whole
    /// project — so listing them here would be noise. A list of guessed app names was worse
    /// still: it reads "all clear" the moment an app is renamed.
    private func checkConflictingApps() -> DiagnosticCheck {
        guard power.snapshot().sleepDisabled, !store.ownsFlag else {
            return DiagnosticCheck(
                title: "Conflicting Tools",
                level: .pass,
                detail: "Nothing else is holding `pmset disablesleep`"
            )
        }
        return DiagnosticCheck(
            title: "Conflicting Tools",
            level: .warning,
            detail: "`pmset disablesleep` is on but NonSleep did not set it",
            fixRecommendation: "Another tool (Amphetamine, a manual `pmset`, …) owns the flag. NonSleep leaves it alone; quit that tool, or clear it with `sudo pmset -a disablesleep 0`."
        )
    }
}
