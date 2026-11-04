# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A configurable heat cut-out with bounded auto-resume. `thermalLimit` (default `serious`) and `backpackThermalLimit` (default `fair`, applied while the lid is closed on battery with no external display) decide when lid-closed mode stops; a closed lid loses the keyboard deck as a heat path, so machines that run hot can stop at `fair` or `nominal`. After the Mac spends `thermalCooldownMinutes` back under the limit, NonSleep resumes on its own up to `thermalRetryLimit` times (default 3) per run. A resumed run that overheats again within `thermalMinRunMinutes` (default 5) ends the retries immediately rather than cycling hot-cold-hot. The budget resets once no lease is live. All five knobs are in `config.json` and in the management window; `nonsleep status` and the menu bar show the trip and resume counters while an episode is running.
- A **Check for updates** button in the management window. It runs only on click — no launch check, no timer, no identifiers — reading the latest release tag from the GitHub API, comparing it with the running version, and linking to the release page. It downloads and installs nothing. Parsing and version ordering live in `NonSleepKit/ReleaseFeed.swift` (no network code), so the CLI, the engine, the MCP server and the reaper remain free of network imports; the one request lives in `NonSleepBar/UpdateCheck.swift`.
- A Homebrew cask (`Casks/nonsleep.rb`): `brew install --cask Tran-Duc-Duy/tap/nonsleep`, updated with `brew upgrade --cask nonsleep`. Uninstalling runs `nonsleep setup --remove` first, so normal sleep, the sudoers rule, the reaper and the CLI link are all cleaned up. `scripts/update-cask.sh vX.Y.Z` repoints the cask at a release using the checksum from that release's `SHA256SUMS.txt`.
- README notes on closed-lid heat and on phone hotspots dropping when the lid closes (macOS low-power Wi-Fi polling plus hinge-antenna attenuation; USB tethering is the fix).

### Changed

- The "100% offline / zero network" wording in the README, `SECURITY.md`, `AGENTS.md` and the landing page is now "no telemetry, no background network", stating the update button as the single, user-initiated exception. The engine, CLI, MCP server and reaper still contain no network code: `grep -rn "URLSession\|import Network\|socket(" Sources/NonSleepKit Sources/nonsleep` returns nothing.

## [0.3.0] - 2026-11-04

### Added

- `nonsleep mcp`: a Model Context Protocol server over stdio, so any MCP-capable agent (Claude Desktop, Cursor, Windsurf, Goose, …) can hold and release leases itself through `nonsleep_status`, `nonsleep_acquire_lease`, and `nonsleep_release_lease`. Stdio only — no network listener, no new dependency.
- `nonsleep doctor`: a read-only check of the sudoers rule, the reaper LaunchAgent, the screen-lock delay, installed agent hooks, and whether another tool owns the `disablesleep` flag.
- `nonsleep history`: recent sessions with duration, battery delta, and the hottest thermal state reached. Bounded by entry count, age, an 80-character ceiling on lease reasons, and a 64 KiB file limit above which the file is discarded rather than parsed; sessions under 5 s are not recorded. About 250 B per session, 12 KB at the cap.
- English and Vietnamese interface, selectable in the menu bar app or through `language` in `config.json` (`auto`, `en`, `vi`). An unrecognised value falls back to `auto` without invalidating the rest of the config.
- An optional chime when the last lease drops, off by default (`soundEnabled`), with an optional custom sound file (`soundPath`).
- Toggles in the management window for the chime and for backpack protection, which previously existed only in `config.json`.
- A landing page at https://nonsleep.vercel.app.

### Changed

- **Backpack protection is on by default.** With the lid closed, on battery, and no external display, NonSleep now releases at a `fair` thermal state instead of waiting for `serious`. A closed Mac in a bag has no airflow, so the earlier cut-out is deliberate — but it does mean such machines sleep sooner than they did in 0.2.0. Set `"backpackProtection": false` to keep the old behaviour.
- Status lines and lease reasons printed by the CLI follow `language`. On a system set to Vietnamese, `auto` now produces Vietnamese output where 0.2.0 always produced English; set `"language": "en"` to pin it.
- The menu bar window no longer has a separate *Custom…* button: the *Keep awake* menu already contained *Custom duration…*, and two entry points for one action is one too many.

## [0.2.0] - 2026-11-02

### Added

- Hook integration for OpenAI Codex CLI (`~/.codex/hooks.json`).
- Custom duration timer input in the menu bar app and management window (e.g. `45m`, `2h`, `1h30m`).
- Helpful descriptive subtitles in the settings window for locks, safeguards, and process lists.
- Usage examples in `nonsleep help`.
- `AGENTS.md` and `llms.txt` specifications for agent and LLM search discoverability.

### Security

- Prevented a TOCTOU race condition in `Setup.installSudoers`: the draft rule is now staged directly into `/etc/sudoers.d/` as `0440 root:wheel` before `visudo -c` validation, preventing unprivileged local processes from swapping the file between check and install.
- Pinned all GitHub Actions in CI and release workflows to immutable commit SHAs.
- Added cryptographic SLSA Level 3 build provenance (`actions/attest-build-provenance`) for all release artifacts.
- Added automated CodeQL static security analysis workflow (`security.yml`) scanning on push, pull request, and weekly schedule.

### Fixed

- Hook commands written by `nonsleep integrate` now quote the CLI path correctly when the app lives in a directory containing an apostrophe.
- Corrected clone directory in README setup instructions.
## [0.1.1] - 2026-10-20

### Changed

- New app icon: a MacBook closed all the way, with a glowing sparkle and a status LED.

## [0.1.0] - 2026-10-20

First public release.

### Added

- Lid-closed mode for macOS: toggles `pmset disablesleep` only while a live lease exists, through a
  sudoers rule that allows exactly `pmset -a disablesleep 0|1`.
- Leases tied to a process, an expiry and the current boot; a LaunchAgent reaper sweeps dead ones
  every minute, so a crash or reboot can't leave the Mac unable to sleep.
- Safety cut-outs: low battery (default < 20%) and serious/critical thermal state; immediate sleep
  when work ends with the lid closed and no external display.
- Agent detection: omp's `"omp agent session"` power assertion (every session, project and
  provider), `caffeinate`, and optional process names.
- Hook integrations for Claude Code, Cursor and Antigravity (`nonsleep integrate`), leaving other
  hooks untouched and keeping a backup of each file.
- Menu bar app with a management window: status, leases with per-lease release, agents,
  integrations, settings, setup check, Sleep now, lock on lid close, launch at login.
- `nonsleep` CLI: `status`, `on`, `off`, `sleep`, `run`, `wait`, `auto`, `reap`, `config`, `setup`,
  `integrate`, `hook`.
- In-app "Finish setup…" (one administrator dialog) and `nonsleep setup`, so the downloaded app
  works without the source tree.
- Linux CLI (x86_64, aarch64): lid-closed mode through a logind `handle-lid-switch:sleep` inhibitor
  held by an on-demand keeper process (no root), omp detection via login1 inhibitors, the same
  hooks, lock on lid close via `loginctl`, and `install.sh` with desktop autostart for `nonsleep auto`.

[Unreleased]: ../../compare/v0.3.0...HEAD
[0.3.0]: ../../compare/v0.2.0...v0.3.0
[0.2.0]: ../../compare/v0.1.1...v0.2.0
[0.1.1]: ../../compare/v0.1.0...v0.1.1
[0.1.0]: ../../releases/tag/v0.1.0
