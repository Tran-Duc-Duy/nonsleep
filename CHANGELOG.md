# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: ../../compare/v0.2.0...HEAD
[0.2.0]: ../../compare/v0.1.1...v0.2.0
[0.1.1]: ../../compare/v0.1.0...v0.1.1
[0.1.0]: ../../releases/tag/v0.1.0
