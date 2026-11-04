# Security Policy

## Supported versions

Security fixes go into the latest release. Please update before reporting.

## Reporting a vulnerability

**Please don't open a public issue.** Use GitHub's private vulnerability reporting: the
**Security** tab of this repository → **Report a vulnerability**. You'll get an acknowledgement
within a few days and a fix or a plan within two weeks for confirmed issues. We credit reporters
in the release notes unless you'd rather stay anonymous.

## What's in scope

NonSleep touches a few privileged or sensitive places; reports about any of them are especially
welcome:

- **The sudoers rule** (`/etc/sudoers.d/nonsleep`): it must allow exactly
  `/usr/bin/pmset -a disablesleep 0` and `… 1`, nothing else, for the installing user only.
- **Setup** (`nonsleep setup`, *Finish setup…*): the administrator command it runs, how the rule
  is validated (`visudo -c`), and user-name handling.
- **Hooks** written into Claude Code, Cursor and Antigravity configs: `nonsleep hook` must never
  approve, block or alter an agent action, and integrations must not drop other hooks.
- **Leases and the reaper**: any way to keep a Mac permanently unable to sleep, or to make the
  reaper act on attacker-controlled input.
- **Lock on lid close**: cases where a closed, awake Mac stays unlocked although the feature is on.

Out of scope: local users who already have administrator rights, and heat or battery wear from
running with the lid closed (documented in the README).

## Security Architecture & Trust Model

### 1. No Background Network, No Telemetry
NonSleep sends **nothing on its own**: no telemetry, no analytics, no crash reporting, no launch check, no timer, no identifiers. The engine, the CLI (`nonsleep`), the MCP server and the reaper contain **zero network code** — they do not import `URLSession`, `Network`, or sockets, and cannot make outbound requests at all.

The single exception is the **Check for updates** button in the menu bar app's window (`Sources/NonSleepBar/UpdateCheck.swift`). When — and only when — you click it, the app issues one HTTPS GET to `api.github.com/repos/Tran-Duc-Duy/nonsleep/releases/latest` over an ephemeral `URLSession` (no cookies, no cache, no credentials), reads the release tag, and compares it with the running version. It sends no data beyond the version string in the `User-Agent`, downloads nothing, and installs nothing. Parsing and version ordering live in `Sources/NonSleepKit/ReleaseFeed.swift`, which has no network code, so the claim above holds for everything except that one button.

### 2. Zero Third-Party Dependencies
The codebase depends on **zero external packages or libraries** (0 npm packages, 0 Swift Package Manager remote dependencies). It links only against the Swift standard library and Apple system frameworks (`AppKit`, `SwiftUI`, `IOKit`, `CoreGraphics`). This eliminates third-party supply-chain compromise vectors.

### 3. Minimal Privilege & TOCTOU-Proof Sudoers Setup
NonSleep requires no background daemon running as root. It requests root access once during setup strictly to install a one-line sudoers rule:
```
you ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```
- **Username Whitelist**: Usernames are strictly validated against `[a-zA-Z0-9._-]` without leading dashes to prevent command or option injection.
- **Root-Staged Validation (No TOCTOU)**: During installation, the draft rule is staged directly into `/etc/sudoers.d/` as `0440 root:wheel` before verification by `/usr/sbin/visudo -cf`. Only after validation succeeds is it atomically moved into place. An unprivileged local process cannot tamper with or swap the staged file.
- **Scope Limitation**: The rule allows only toggling `pmset -a disablesleep`. It cannot execute arbitrary code, modify system files, or read sensitive data.

### 4. Hook Isolation & Privacy
Hooks configured for Claude Code, Cursor, and Antigravity:
- Never approve, deny, or modify any agent actions (always exit 0).
- Never inspect or exfiltrate prompt text, code diffs, or API keys.
- Only receive hook event notifications to track turn start and end times.
- Original hook configuration files are backed up to `.nonsleep-backup` before modification.

### 5. Supply Chain & Build Provenance
- GitHub Actions workflows pin all third-party actions to immutable commit SHAs.
- Official release binaries are built publicly on GitHub Actions and signed with GitHub Artifact Attestations (SLSA Level 3 build provenance).

### 6. Physical & Screen Lock Protection
- When closing the lid while awake, NonSleep provides automatic screen locking via `pmset displaysleepnow` (or `loginctl lock-session` on Linux). For guaranteed protection, configure macOS: **System Settings › Lock Screen › Require password after display turns off: Immediately**.
- Automatic safety cut-outs immediately release sleep inhibition if battery level drops below 20% or thermal state reaches serious/critical levels.

---

## Independent Verification Guide

You do not have to trust pre-built binaries or claims. You can verify everything yourself:

### 1. Verify There Is No Background Network Activity
Inspect running processes to confirm NonSleep holds no sockets:
```sh
lsof -p "$(pgrep -f 'NonSleep|nonsleep' | tr '\n' ',')" -i
```
Expected output: empty, unless you clicked *Check for updates* in the last few seconds. The CLI, the reaper and the MCP server never open a socket at any point; grep the sources for the proof:
```sh
grep -rn "URLSession\|Network\|socket(" Sources/NonSleepKit Sources/nonsleep
```
Expected output: empty — every network call in the project lives in `Sources/NonSleepBar/UpdateCheck.swift`.

### 2. Verify Release Provenance
Verify that release assets were built directly on GitHub Actions from this repository's source code:
```sh
gh attestation verify NonSleep-*-macOS.zip --owner Tran-Duc-Duy
```

### 3. Verify Sudoers File
Check that `/etc/sudoers.d/nonsleep` grants only the two permitted commands:
```sh
cat /etc/sudoers.d/nonsleep
```

### 4. Build from Source
If you prefer full control, build and install locally with the Swift compiler:
```sh
git clone https://github.com/Tran-Duc-Duy/nonsleep.git && cd nonsleep
scripts/install.sh
```
