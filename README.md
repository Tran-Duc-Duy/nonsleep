<p align="center"><img src="Resources/AppIcon.png" width="160" alt="NonSleep icon"></p>

# NonSleep

[![CI](https://github.com/Tran-Duc-Duy/nonsleep/actions/workflows/ci.yml/badge.svg)](https://github.com/Tran-Duc-Duy/nonsleep/actions/workflows/ci.yml)
[![Security Scan](https://github.com/Tran-Duc-Duy/nonsleep/actions/workflows/security.yml/badge.svg)](https://github.com/Tran-Duc-Duy/nonsleep/actions/workflows/security.yml)
![Offline](https://img.shields.io/badge/Telemetry-None%20%C2%B7%20No%20background%20network-2ea44f)
![Dependencies](https://img.shields.io/badge/Dependencies-0%20(Pure%20Swift)-2ea44f)

Keep your Mac working **with the lid closed** while your AI coding agents run — and let it sleep again the moment they finish.

`caffeinate`, Amphetamine's basic mode, and agents' own "prevent sleep" settings all use `IOPMAssertion`, which only blocks *idle* sleep. Closing the lid still sleeps the Mac. The only switch that survives a closed lid is the system flag `pmset disablesleep 1`, which needs root and is easy to forget on. NonSleep turns that flag on only while something actually needs it, and guarantees it turns off again.

- **Agent-aware.** [omp](https://github.com/can1357/oh-my-pi) holds an `"omp agent session"` power assertion exactly while a prompt is in flight, in every project and with every provider; NonSleep watches for it (and for `caffeinate`). Claude Code, Cursor, Antigravity and Codex report their turns through official hooks that `nonsleep integrate` installs. A closed MacBook keeps running a long turn — in a terminal, an IDE, or inside Orca — and sleeps when it's done.
- **Menu bar app + CLI**, sharing one state: `nonsleep run claude`, `nonsleep on 3h`, `nonsleep wait 1234`.
- **Fail-safe.** Every request is a *lease* tied to a process, an expiry, and the current boot. Crash, `kill -9`, or reboot → the lease dies → a LaunchAgent reaper (every 60 s) restores normal sleep on its next run.
- **Safety cut-outs.** Suspended on battery below 20% and when macOS reports serious/critical thermal state. When the flag drops with the lid closed (and no external display), the Mac sleeps immediately.
- **Minimal privilege.** A sudoers rule that allows exactly `pmset -a disablesleep 0` and `… 1`. No helper daemon running as root, no telemetry, and no network traffic unless you press *Check for updates*.

### Why NonSleep?

| What you want to do | Amphetamine / Caffeinate | NonSleep |
|---|---|---|
| **Close lid & keep working** | ❌ Forces Mac to sleep immediately | ✅ Keeps running with lid closed |
| **Auto-sleep when AI agent finishes** | ❌ No awareness; stays on indefinitely | ✅ Auto-sleeps the moment prompt ends |
| **Listen to YouTube / Music with lid closed** | ⚠️ Needs manual timer, risk of draining battery | ✅ Custom timer (`45m`, `2h`) + <20% battery auto-cutoff |
| **Overheating / Battery drain in backpack** | ❌ No safety; runs battery to 0% and gets hot | ✅ Automatic thermal & battery cut-outs |
| **Privacy when closing lid** | ❌ Leaves session unlocked | ✅ Automatically locks screen on lid close |

### Common Use Cases

1. **AI Coding Agents (Hands-free)**: Turn on hooks once (`nonsleep integrate all`). Run Claude Code, Cursor, Codex, or omp. Close your MacBook and head home; when the prompt or turn ends, your Mac goes to sleep automatically.
2. **Listen to YouTube / Podcasts / Audio with Lid Closed**: Click **Custom…** in the menu bar or run `nonsleep on 45m`. Your Mac keeps playing audio with the lid closed and goes to sleep when the timer expires.
3. **Long Downloads, Builds, or Renders**: Run `nonsleep run -- npm run build` or `nonsleep wait <PID>`. Close the lid; your Mac sleeps the second the process exits.

## Install

### Homebrew (macOS 13+)

```sh
brew install --cask Tran-Duc-Duy/tap/nonsleep
```

Then click **Finish setup…** in the NonSleep window (or run `nonsleep setup`) once, to install the sudoers rule. Updating later is `brew upgrade --cask nonsleep`; `brew uninstall --cask nonsleep` restores normal sleep and removes the sudoers rule, the reaper and the CLI link before it deletes the app. The cask source lives in [`Casks/nonsleep.rb`](Casks/nonsleep.rb).

### Download (macOS 13+)

1. Download `NonSleep-X.Y.Z-macOS.zip` from [Releases](../../releases/latest), unzip, and move
   **NonSleep.app** to `/Applications` or `~/Applications`. It's a universal app (Apple silicon and Intel).
2. The app is ad-hoc signed, not notarized (Apple requires a paid $99/yr developer account for notarization), so macOS Gatekeeper prompts an unverified developer warning on first launch. Open it once, then go to *System Settings › Privacy & Security* and click **Open Anyway**, or run:
   ```sh
   xattr -dr com.apple.quarantine /Applications/NonSleep.app
   ```
3. The NonSleep window opens: click **Finish setup…** and approve the administrator dialog.

Verify download integrity and cryptographic build provenance:
```sh
# Verify SLSA build provenance (verifies binary was built on GitHub Actions from this repo)
gh attestation verify NonSleep-*.zip --owner Tran-Duc-Duy

# Or check SHA-256 checksum against SHA256SUMS.txt in the release
shasum -a 256 NonSleep-*.zip
```

### Updating

NonSleep never checks for updates on its own: no launch check, no timer, no telemetry. The management window has a **Check for updates** button that reads the latest release tag from the GitHub API *only when you click it*, compares it with the running version, and links to the release page. It downloads and installs nothing.

| Installed with | Update |
| --- | --- |
| Homebrew | `brew upgrade --cask nonsleep` |
| Zip download | Download the new zip from [Releases](../../releases/latest) and replace the app |
| From source | `git pull && scripts/install.sh` |

### From source

Requires the Swift toolchain (Xcode or Command Line Tools).

```sh
git clone <this repo> && cd nonsleep
scripts/install.sh        # builds, installs ~/Applications/NonSleep.app, runs `nonsleep setup`
nonsleep status
```

### What setup installs

*Finish setup…* and `nonsleep setup` do the same thing; only the sudoers step needs the administrator dialog:

| What | Where |
| --- | --- |
| sudoers rule | `/etc/sudoers.d/nonsleep` |
| Reaper LaunchAgent (`nonsleep reap` at login + every 60 s) | `~/Library/LaunchAgents/dev.nonsleep.reaper.plist` |
| CLI symlink | `~/.local/bin/nonsleep` → the CLI inside the app |

The rule, validated with `visudo -c` before it's installed:

```
you ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

Uninstall: `scripts/uninstall.sh`, or `nonsleep integrate all --remove && nonsleep setup --remove`
and delete the app. Either way normal sleep is restored first.

### Linux (CLI)

Laptops on systemd distributions suspend on lid close by default (`HandleLidSwitch=suspend`). NonSleep for Linux is the same CLI (`status`, `on`, `run`, `wait`, `auto`, `integrate`, hooks…), no menu bar app, and **no root**:

```sh
tar -xzf nonsleep-X.Y.Z-linux-x86_64.tar.gz && cd nonsleep-X.Y.Z-linux-x86_64   # or -aarch64
./install.sh          # ~/.local/bin/nonsleep + autostart `nonsleep auto` in your desktop session
nonsleep status
```

From source: `scripts/install-linux.sh` (needs Swift 6). Uninstall: `./uninstall.sh` / `scripts/uninstall-linux.sh`.

How it differs from macOS:

- Lid-closed mode is a logind **inhibitor lock** (`handle-lid-switch:sleep`, block mode) held by a small `nonsleep keeper` process that exists only while a live lease does. If it or `systemd-inhibit` dies, logind drops the lock, so there's no sudoers rule and no reaper.
- omp holds a login1 inhibitor while a turn runs; NonSleep reads it via `busctl … ListInhibitors`. Hooks for Claude Code, Cursor and Antigravity work the same as on macOS.
- Lock on lid close uses `loginctl lock-session`; "sleep now" uses `systemctl suspend`. There's no thermal cut-out on Linux (battery cut-out only).
- Polkit lets processes in your **active local session** take these locks; over SSH they're refused. That's why `install.sh` uses desktop autostart for `nonsleep auto` rather than a `systemd --user` service.
- State lives in `~/.local/state/nonsleep`, config in `~/.config/nonsleep/config.json`.

## Use

### Menu bar and window

The moon (`moon.zzz`) means normal sleep, the pulse (`waveform.path.ecg`) means the lid can close, and ⚠︎ means a safety cut-out paused it or something failed.

The menu has the essentials:

- **Auto: while agents are working** (on by default)
- **Keep awake** → 1 h / 3 h / 8 h / until turned off
- **Turn off** releases every lease, including ones made from the CLI, and disables auto mode
- **Sleep now** releases everything and sleeps the Mac. While NonSleep holds the Mac awake, macOS ignores the Apple-menu Sleep item and the power button; this always works. Auto mode pauses until you wake the screen, so a dark wake can't re-arm it.
- **Open NonSleep…** (⌘,) opens the window

The window also opens when you open the app again from Finder/Spotlight, and on first launch or while setup is incomplete. It shows what is holding the Mac awake (with **Release** per lease), which agents are working, every config setting (saved straight to `config.json`), **Launch at login**, and a setup check (sudoers rule, reaper, screen-lock delay). The app sits in the Dock only while the window is open.

**Lock on lid close** (on by default): when the lid closes while NonSleep keeps the Mac awake, and no external display is attached, the app turns the display off (`pmset displaysleepnow`). Without this, a closed-but-awake Mac stays unlocked: whoever opens the lid is straight in. The lock only happens if *System Settings › Lock Screen › Require password after screen saver begins or display is turned off* is **Immediately**; the setup check shows the current value.

Leases held by the app die with the app: quitting releases them, and if nothing else holds a lease, normal sleep returns (immediately, if the lid is closed).

Logs: `log show --last 1h --predicate 'subsystem == "dev.nonsleep.app"'`.

### CLI

```text
nonsleep status               lid-closed mode, leases, agent activity, power
nonsleep on [DURATION]        detached: until `off`, DURATION (90m, 3h, 1h30m), or reboot
nonsleep off                  release every lease, restore normal sleep
nonsleep sleep                release every lease and sleep now
nonsleep run [--] CMD…        hold while CMD runs; exits with CMD's status
nonsleep wait TARGET…         hold while PIDs or process names (claude, omp) run
nonsleep auto                 headless auto mode (same logic as the menu bar app)
nonsleep reap                 sweep dead leases, re-apply state (LaunchAgent)
nonsleep config               print config path and effective config
nonsleep doctor               verify sudoers, reaper, screen lock, hooks, and conflicting apps
nonsleep history [--clear]    show recent sleep session history, duration and battery stats
nonsleep mcp                  run stdio Model Context Protocol server for AI coding agents
nonsleep integrate [AGENT…]   add hooks for claude / cursor / antigravity / all (--remove to undo); no AGENT: status
nonsleep hook AGENT EVENT     what those hooks call (event JSON on stdin; always exits 0)
```

`run` spawns the command in your terminal's foreground process group, so interactive TUIs keep working and Ctrl-C goes straight to them.

`off` (and **Turn off** in the menu) drops the leases that exist *now*. A `run`, `wait`, or `auto` process that is still running takes its lease back on its next tick (10–15 s), so stop that process if you want it to stay off.

### Agents

| Agent | How NonSleep sees it |
| --- | --- |
| omp | Built in: the `"omp agent session"` assertion, held only while a turn is in flight, for every session, project and provider (omp setting `power.sleepPrevention` must not be `off`). |
| Claude Code | `nonsleep integrate claude` → hooks in `~/.claude/settings.json` (`UserPromptSubmit`, `PostToolUse` hold; `Stop`, `StopFailure`, `Notification`, `SessionEnd` release). |
| Cursor (IDE agent) | `nonsleep integrate cursor` → hooks in `~/.cursor/hooks.json` (`beforeSubmitPrompt` and post-tool events hold; `stop`, `sessionEnd` release). Only observe-only events are used, so NonSleep never approves or blocks a tool call. |
| Antigravity (App, IDE, CLI) | `nonsleep integrate antigravity` → a `nonsleep` entry in `~/.gemini/config/hooks.json` (`PreInvocation`, `PostToolUse` hold; `Stop` releases once `fullyIdle`). |
| Agents inside Orca | Detected the same way as in any terminal. To hold while Orca is open at all, add `"Orca"` to `processNames`. |
| Anything else | `nonsleep run <cmd>`, `caffeinate -i <cmd>`, or `nonsleep wait <pid>`. |

Hook integrations: `nonsleep integrate` shows what's installed, `nonsleep integrate all` installs everything, `--remove` takes it out again (the window has a toggle per agent). NonSleep only adds or removes its own entries; other hooks in those files (Orca's, for example) are left as they are, and the first edit saves a `.nonsleep-backup` copy. The rewritten file is pretty-printed with sorted keys.

Each turn's lease belongs to the agent process that ran the hook (the first ancestor that isn't a shell), so it dies with the agent, and expires `hookTimeoutMinutes` after the agent's last hook event. That covers turns that end without a stop event (Claude Code skips `Stop` on user interrupt). A single tool call that runs longer than that without any hook firing (a long build) can let the lease lapse; wrap it in `nonsleep run` or raise the timeout. Cursor's CLI (`cursor-agent`) does not emit `beforeSubmitPrompt`/`stop`, so it only holds from post-tool events.

`processNames` match the executable name or the script an interpreter runs (`bun …/omp` matches `omp`). Presence alone counts, so an idle `claude` session keeps the Mac awake; prefer hooks, `run`, or the assertion signal when you can.

### Config

`~/Library/Application Support/NonSleep/config.json` — every key optional:

```json
{
  "assertionNames": ["omp agent session", "caffeinate"],
  "processNames": [],
  "minBatteryPercent": 20,
  "graceSeconds": 120,
  "sleepWhenDone": true,
  "lockOnLidClose": true,
  "hookTimeoutMinutes": 30,
  "soundEnabled": false,
  "soundPath": null,
  "backpackProtection": true,
  "thermalLimit": "serious",
  "backpackThermalLimit": "fair",
  "thermalRetryLimit": 3,
  "thermalCooldownMinutes": 3,
  "thermalMinRunMinutes": 5,
  "historyMaxEntries": 50,
  "historyRetentionDays": 30,
  "language": "auto"
}
```

- `assertionNames`: case-insensitive substrings of power-assertion names (`pmset -g assertions`).
- `graceSeconds`: auto mode keeps holding this long after the last activity, which covers the gap between turns.
- `sleepWhenDone`: when the flag drops with the lid closed and no external display, run `pmset sleepnow`.
- `lockOnLidClose`: menu bar app only; see *Lock on lid close* above.
- `hookTimeoutMinutes`: how long a hook-reported turn holds after the agent's last hook event.
- `soundEnabled` / `soundPath`: chime when the last lease drops. `soundPath` takes any `.aiff`/`.wav`/`.mp3`; `null` uses the macOS system sound.
- `backpackProtection`: with the lid closed on battery and no external display, apply `backpackThermalLimit` instead of `thermalLimit` — a closed Mac in a bag has no airflow.
- `thermalLimit` / `backpackThermalLimit`: `nominal`, `fair`, `serious`, or `critical`. Lid-closed mode stops at or above that state. Closing the lid removes the keyboard deck from the heat path, so a Mac that feels too hot in your bag should run at `fair` (or `nominal` for a hard stop on any heat at all).
- `thermalRetryLimit` / `thermalCooldownMinutes` / `thermalMinRunMinutes`: after a heat stop, NonSleep waits `thermalCooldownMinutes` under the limit and resumes, up to `thermalRetryLimit` times per run. A resumed run that overheats again within `thermalMinRunMinutes` proves cooling isn't helping, so NonSleep stops retrying and says so in the status line. `thermalRetryLimit: 0` never resumes on its own. The budget resets when every lease is gone (`nonsleep off`, or the agent finishing).
- `historyMaxEntries` / `historyRetentionDays`: bounds on `history.json`. `historyMaxEntries: 0` turns history off; `historyRetentionDays: 0` keeps entries until the count evicts them.
- `language`: `auto` (follow the system), `en`, or `vi`. The menu bar app has a picker under *Settings*; the CLI uses it for status lines and lease reasons. An unrecognised code falls back to `auto` without invalidating the rest of the config.

### Session history

`nonsleep history` prints recent sessions with duration, battery delta, and the hottest thermal state reached. The file can't grow unbounded:

| Bound | Effect |
| --- | --- |
| `historyMaxEntries` (50) | Oldest sessions are evicted on every write. |
| `historyRetentionDays` (30) | Entries past the window are dropped on the next write. |
| 80-character reason | Lease reasons (including arbitrary text from MCP callers) are truncated before they are written. |
| 5-second minimum | A reconcile that flips the flag twice isn't a session and isn't recorded. |
| 64 KiB file ceiling | A file over the ceiling is deleted instead of parsed, so a corrupt or tampered file can't be loaded into memory. |

At the defaults that is ~250 B per session and ~12 KB at the cap. `nonsleep history --clear` removes the file.

### Heat with the lid closed

A closed lid removes the keyboard deck from the cooling path, so the same workload that is comfortable with the lid open runs hotter once the Mac is shut. NonSleep does not add load, but it is what lets the load keep running, so it owns the cut-out:

| Control | Default | What it does |
| --- | --- | --- |
| `thermalLimit` | `serious` | Lid-closed mode stops at or above this state. |
| `backpackThermalLimit` | `fair` | Stricter ceiling while enclosed (lid closed, on battery, no external display). |
| `sleepWhenDone` | `true` | On a heat stop with the lid closed, the Mac sleeps immediately — the fastest way to cool it. |
| `thermalRetryLimit` | `3` | Auto-resumes granted after it cools back under the limit. |
| `thermalMinRunMinutes` | `5` | A resumed run that overheats again this fast ends the retries for this run. |

If the machine still gets hotter than you want: set `thermalLimit` to `fair`, raise `thermalMinRunMinutes`, and keep the Mac on a hard surface rather than a bag or a bed, where the aluminium bottom is the only remaining heat path. `nonsleep status` shows the trip and resume counters while an episode is running.

### Personal hotspot drops when the lid closes

A Wi-Fi router keeps transmitting whether or not your Mac is listening; a phone hotspot does not. With the lid closed, macOS puts the Wi-Fi chip into low-power polling and the hinge antenna loses several dB behind the closed display, so the phone sees no traffic and shuts the hotspot off to save its own battery. NonSleep cannot change either side of that — it holds no network state and makes no network calls at all.

What works, in order: **USB tethering** over the charging cable (it enumerates as a wired interface, so neither end can idle it out), iPhone *Settings › Personal Hotspot › Maximize Compatibility* (2.4 GHz penetrates the closed lid better than 5 GHz), and keeping the phone plugged in while it shares. A Mac on router Wi-Fi is unaffected.

## How it works

```mermaid
flowchart LR
    CLI[nonsleep CLI] -->|lease| L[(leases/*.json)]
    App[Menu bar app] -->|lease| L
    Reaper[LaunchAgent reaper<br/>every 60 s] --> R
    L --> R{reconcile<br/>under flock}
    R -->|live lease and safe| On[sudo pmset -a disablesleep 1]
    R -->|no live lease, low battery or hot| Off[sudo pmset -a disablesleep 0<br/>+ sleepnow if lid closed]
```

A lease is alive while its boot time matches, it has not expired, and (if owned) its owner PID still has the same start time, which also guards against PID reuse. Whoever reconciles first sweeps dead leases. NonSleep only turns the flag off if NonSleep turned it on, so it never fights Amphetamine or a manual `pmset`.

Source map (`Sources/`):

| File | Role |
| --- | --- |
| `NonSleepKit/NonSleep.swift` | reconcile engine, safety policy |
| `NonSleepKit/Lease.swift` | lease lifetime, on-disk store, cross-process lock |
| `NonSleepKit/ThermalGuard.swift` | heat ceilings, cooldown and auto-resume budget |
| `NonSleepKit/Power.swift` | IOKit reads (flag, lid, battery, displays, thermal), `pmset` calls |
| `NonSleepKit/Processes.swift` | libproc/sysctl process info, power assertions |
| `NonSleepKit/Agents.swift` | agent activity matching, grace window |
| `NonSleepKit/Lid.swift` | lid open/close events (IOKit clamshell message) |
| `NonSleepKit/Setup.swift` | install checks: sudoers rule, reaper, screen-lock delay |
| `NonSleepKit/Integrations.swift` | Claude Code / Cursor / Antigravity hooks: event → action, config install/remove |
| `nonsleep/main.swift` | CLI |
| `NonSleepBar/NonSleepBarApp.swift` | app entry, delegate, menu bar menu |
| `NonSleepBar/BarModel.swift` | state and actions shared by menu and window |
| `NonSleepBar/MainWindow.swift` | management window |

## Security, Privacy & Auditability

NonSleep is designed for maximum transparency and minimal privilege:

- **No telemetry, no background network**: Nothing is ever sent on its own — no analytics, no crash reports, no launch check. The engine, the CLI, the MCP server and the reaper contain no network code at all (`grep -rn "URLSession\|import Network\|socket(" Sources/NonSleepKit Sources/nonsleep` returns nothing). The only request the project can make is the *Check for updates* button in the app window, which reads the latest release tag from the GitHub API on click and downloads nothing. Verify with `lsof -p "$(pgrep -f 'NonSleep|nonsleep' | tr '\n' ',')" -i`.
- **Zero Third-Party Dependencies**: 0 npm packages, 0 Swift Package Manager remote dependencies. Links only standard library and Apple system frameworks (`AppKit`, `SwiftUI`, `IOKit`, `CoreGraphics`).
- **Minimal Privilege (No Root Daemon)**: Does not run any background daemon as root. Setup requests administrator rights once to install a single-line sudoers rule strictly limited to `/usr/bin/pmset -a disablesleep 0` and `1`.
- **TOCTOU-Proof Setup**: The sudoers file is staged into `/etc/sudoers.d/` as `0440 root:wheel` before `visudo -c` validation to prevent local race conditions.
- **Non-Intrusive Agent Hooks**: Hook scripts for Claude Code, Cursor, and Antigravity only notify when turns start and finish. They never approve, deny, modify, or read agent prompt contents.
- **Verifiable Supply Chain**: All CI/release GitHub Actions are pinned to immutable commit SHAs, and release artifacts include GitHub Artifact Attestations (SLSA Level 3).
- **Build from Source**: If you prefer not to run pre-compiled binaries, building directly from source takes ~30 seconds: `git clone https://github.com/Tran-Duc-Duy/nonsleep.git && cd nonsleep && scripts/install.sh`.

See [SECURITY.md](SECURITY.md) for full threat model details and reporting procedures.

### Performance & Resource Benchmark

Built with pure Swift, AppKit, and SwiftUI — no Electron, no Node.js, and zero background polling:

| Metric | NonSleep Measurement | Real-World Impact |
|---|---|---|
| **App Bundle Size** | **4.5 MB** | Universal binary (`arm64` + `x86_64`) + icon assets |
| **CLI Binary Size** | **601 KB** | Standalone native binary (`nonsleep`), including the MCP server and both languages |
| **Idle CPU Usage** | **0.0% – 0.1%** | Pure IOKit event-driven callbacks; zero CPU wakeups |
| **CLI Execution Speed** | **~0.03 seconds** | Subcommands execute in ~30 ms, then immediately exit |
| **Memory (RAM)** | **~3.9 MB** (CLI) / **~25 MB** (App) | Native lightweight footprint vs 300–800 MB for Electron apps |
| **Disk Storage Footprint** | **< 10 KB total** | Config (~300 B) + ephemeral leases (~150 B); zero database |
| **Zero Junk / Zero Logs** | **0 disk bloat** | No SQLite, no log files, dead leases swept every 60s |
| **Battery Protection** | **Automatic cut-out** | Drops sleep assertion if battery < 20% or thermal warning |

## Caveats

- A closed, awake MacBook in a bag gets hot. The thermal cut-out helps, but don't rely on it alone.
- While a lease is held, macOS does not sleep at all: no idle sleep, and the Apple-menu Sleep item and power button do nothing. Use **Sleep now** / `nonsleep sleep`.
- Release builds are ad-hoc signed, not notarized (no Apple Developer ID yet), hence the one-time *Open Anyway* step. Builds you make yourself aren't quarantined.

## Develop

```sh
swift build
scripts/test.sh                                # swift test; also works with only the Command Line Tools
scripts/build-app.sh                           # → build/NonSleep.app  (ARCHS="arm64 x86_64" for universal, needs Xcode)
swift scripts/make-icon.swift Resources/AppIcon.png   # regenerate the icon (drawn in CoreGraphics)
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and the release process (push a `vX.Y.Z` tag; CI builds and publishes the release), and [SECURITY.md](SECURITY.md) for reporting vulnerabilities. Changes are listed in [CHANGELOG.md](CHANGELOG.md).

## License

[MIT](LICENSE)
