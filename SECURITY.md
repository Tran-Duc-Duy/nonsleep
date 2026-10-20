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
