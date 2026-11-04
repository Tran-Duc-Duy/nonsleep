# NonSleep — Agent & Developer Guide

NonSleep is an open-source, agent-aware power management tool for macOS (13+) and Linux. It allows MacBooks to continue running tasks **with the lid closed without an external display**, specifically while AI coding agents or long scripts are active, and automatically puts the machine to sleep the moment work completes.

---

## 1. Core Mental Model

Standard macOS sleep prevention tools (`caffeinate`, Amphetamine's default mode, or IDE assertion APIs) use `IOPMAssertionCreateWithName`. This only blocks **idle system sleep**. When a MacBook lid is closed without an external monitor connected, macOS ignores `IOPMAssertion` and forces sleep immediately.

The only macOS switch that keeps a closed MacBook awake is the root-level system flag:
```sh
sudo pmset -a disablesleep 1  # keeps Mac awake with lid closed
sudo pmset -a disablesleep 0  # restores normal sleep
```

NonSleep automates this flag safely:
1. It turns `pmset -a disablesleep 1` on **only while a live lease exists**.
2. Each lease is tied to a process ID (PID), boot time, and timeout.
3. If an agent finishes, crashes, or times out, the lease expires.
4. A background LaunchAgent reaper (`dev.nonsleep.reaper`, running every 60s) sweeps expired/dead leases and restores `pmset -a disablesleep 0`.
5. On Linux, NonSleep uses systemd `logind` inhibitor locks (`handle-lid-switch:sleep`) without root.

---

## 2. Architecture & File Layout

- **`Sources/NonSleepKit/`**: Core engine shared between CLI and GUI.
  - `NonSleep.swift`: Engine state machine, status reporting, reconcile logic.
  - `Lease.swift`: Lease data structures and on-disk lease store (`~/Library/Application Support/NonSleep/leases/`).
  - `Integrations.swift`: Official hook integration logic for AI coding agents.
  - `Setup.swift`: Sudoers rule installation with TOCTOU-proof root staging and reaper LaunchAgent.
  - `MacPower.swift` / `LinuxPower.swift`: Platform power controls (`pmset` vs `logind`).
  - `Lid.swift`: IOKit clamshell event listener.
  - `Processes.swift`: Process introspection, PID start time tracking (PID reuse guard).
- **`Sources/nonsleep/`**: Native CLI binary (`nonsleep`).
- **`Sources/NonSleepBar/`**: Native macOS Menu Bar application (AppKit + SwiftUI).
- **`scripts/`**: Build, packaging, install, and uninstall helper scripts.

---

## 2b. Git Workflow (read before writing any code)

Branch from an up-to-date `main`, never from the branch that happens to be checked out:

```sh
git checkout main && git pull --ff-only origin main
git checkout -b feat/<short-name>
```

- `release/*` branches exist only to cut a tag. `main` carries the **squashed** version of their
  release commit under a different SHA, so branching from a release branch puts a duplicate
  commit in the PR and GitHub reports a CHANGELOG conflict unrelated to the actual change.
- Keep the branch current with `git fetch origin && git rebase origin/main`, not `git merge main`.
- A duplicate commit already on the branch is dropped during the rebase, not merged by hand:
  `git rebase --onto origin/main <last-unwanted-commit>` then `git push --force-with-lease`.
- Every commit must build and pass `swift test` on its own; splitting a change across commits
  means splitting its tests and `Localization.swift` cases with it.
- Before pushing, run what CI runs: `swift build`, `swift test`, `npx tsc --noEmit` in `web/`
  when web files changed, and `shellcheck scripts/*.sh` when scripts changed.
- After a PR is squash-merged, delete the branch and start the next one from a fresh `main`.

---

## 3. Supported AI Agents & Hook Integrations

NonSleep monitors agents via three mechanisms:

### A. Automatic Power Assertion (Zero setup needed)
- **omp (oh-my-pi)**: Automatically detected via its `"omp agent session"` power assertion. NonSleep reads this directly from IOKit.
- **caffeinate**: Detected via `"caffeinate command-line tool"` assertion.

### B. Lifecycle Hooks (`nonsleep integrate`)
NonSleep installs lightweight command hooks that notify when a prompt turn starts (`.working`) and ends (`.finished`):
- **Claude Code**: `~/.claude/settings.json` (`UserPromptSubmit`, `PostToolUse`, `Stop`, `SessionEnd`).
- **Cursor**: `~/.cursor/hooks.json` (`beforeSubmitPrompt`, `postToolUse`, `afterShellExecution`, `afterFileEdit`, `stop`, `sessionEnd`).
- **Antigravity**: `~/.gemini/config/hooks.json` (`PreInvocation`, `PostToolUse`, `Stop`).
- **OpenAI Codex**: `~/.codex/hooks.json` (`UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `SubagentStop`).

Hooks are strictly passive:
- They always exit 0.
- They never read prompt contents, code, or tokens.
- They never approve, reject, or modify agent actions.
- Original hook files are backed up to `.nonsleep-backup`.

### C. Model Context Protocol (`nonsleep mcp`)
Any agent supporting standard MCP (Claude Desktop, Cursor, Windsurf, OpenCode, Goose) can run `nonsleep mcp` over stdio to programmatically acquire and release leases.

### D. Process Monitoring & Custom Timers
- Users can list process names in config (e.g. `codex`, `rsync`, `brew`).
- Users can specify custom durations (e.g. `45m`, `2h`, `1h30m`) in GUI or CLI.

---

## 4. CLI Quick Reference

```sh
nonsleep status               # View current sleep mode, active leases, power state, and agents
nonsleep run -- <command>     # Keep awake while command runs; sleep when it exits
nonsleep wait <target...>     # Keep awake while target PIDs or process names run
nonsleep on [DURATION]        # Keep awake with lid closed (e.g. 45m, 2h, 90s, or until off)
nonsleep off                  # Release all leases and restore normal sleep immediately
nonsleep sleep                # Release all leases and put the Mac to sleep right now
nonsleep auto                 # Run foreground watcher for agent activity
nonsleep integrate [agent...] # Install hooks for claude, cursor, antigravity, codex, or all
nonsleep setup                # Install sudoers rule, reaper LaunchAgent, and CLI link
nonsleep doctor               # Verify sudoers, reaper, screen lock, hooks, and conflicting apps
nonsleep history [--clear]    # View recent sleep sessions with battery delta and peak thermal
nonsleep mcp                  # Run Model Context Protocol server over stdio for AI coding agents
```

---

## 5. Security & Trust Invariants

1. **No telemetry, no background network**: Nothing is sent on its own — no analytics, no crash reports, no launch check. `NonSleepKit`, the CLI, the MCP server and the reaper contain zero network imports (`URLSession`, `Network`, sockets); `grep -rn "URLSession\|import Network\|socket(" Sources/NonSleepKit Sources/nonsleep` must stay empty. The sole network call in the project is the user-initiated *Check for updates* button (`Sources/NonSleepBar/UpdateCheck.swift`), which reads the latest release tag from the GitHub API on click and downloads nothing; its parsing and version ordering live in `NonSleepKit/ReleaseFeed.swift`.
2. **Zero Dependencies**: 0 npm packages, 0 Swift Package Manager remote dependencies. Links only standard library and Apple system frameworks (`AppKit`, `SwiftUI`, `IOKit`, `CoreGraphics`).
3. **Restricted Sudoers Scope**: Allows exclusively:
   ```
   you ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
   ```
   Username is sanitized with a strict character whitelist (`[a-zA-Z0-9._-]`).
4. **TOCTOU-Proof Installation**: The draft sudoers rule is staged as `0440 root:wheel` in `/etc/sudoers.d/` before `visudo -c` verification, preventing local race conditions.
5. **Safety Cut-outs**: Sleep inhibition is automatically suspended if battery level drops below 20% or thermal state reaches serious/critical levels.
6. **Screen Lock on Lid Close**: Displays are turned off on lid close (`pmset displaysleepnow`), ensuring the macOS session is locked immediately.
7. **Bounded On-Disk State**: `history.json` is capped four ways — entry count (`historyMaxEntries`, 50), age (`historyRetentionDays`, 30), an 80-character ceiling on lease reasons, and a 64 KiB file limit above which the file is deleted rather than parsed. Sessions under 5 s are not recorded. Steady-state footprint is ~12 KB.
8. **Localization**: UI text lives in `NonSleepKit/Localization.swift` as a compiled-in `L10n` enum (English + Vietnamese), not `.lproj` bundles — `Package.swift` declares no resources and `build-app.sh` assembles the bundle by hand. Keyed cases mean a missing translation is a compile error, and the CLI and app share one table. Language comes from `config.language` (`auto`/`en`/`vi`).
