## What and why

<!-- What does this change, and what problem does it solve? Link the issue: Fixes #123 -->

## How it was tested

<!-- Tests added/updated, and what you ran or clicked through (app changes: which macOS). -->

## Checklist

- [ ] `swift build` and `scripts/test.sh` pass, with no new warnings
- [ ] Changes to leases / `apply()` / the reaper come with a test that would catch a stuck flag
- [ ] Hooks still exit 0 and never approve, block or alter agent actions
- [ ] User-visible change noted under **[Unreleased]** in `CHANGELOG.md`
- [ ] README updated if commands, config keys or behavior changed
