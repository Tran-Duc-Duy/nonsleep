# Contributing to NonSleep

Thanks for helping! Bug reports, agent integrations, docs fixes and code are all welcome.

## Before you start

- **Bugs**: open an issue with the bug template. Include `nonsleep status`, macOS version, and,
  for app problems, `log show --last 30m --predicate 'subsystem == "dev.nonsleep.app"'`.
- **Features / new agent integrations**: open an issue first so we can agree on the approach.
  A new agent needs a reliable "turn started / turn ended" signal (an official hook, a power
  assertion, an inhibitor lock…); process presence alone keeps machines awake forever.
- **Security issues**: don't open a public issue — see [SECURITY.md](SECURITY.md).

## Development setup

Requires macOS 13+ and Swift 6 (Xcode 16+, or the Command Line Tools). The Linux CLI builds with
Swift 6 on any systemd distribution; from a Mac, `docker run --rm -v "$PWD":/src -w /src swift:6.3-noble swift test`
runs the suite on Linux.

```sh
swift build                    # library, CLI, menu bar app
scripts/test.sh                # tests (works with full Xcode or only the Command Line Tools)
scripts/build-app.sh           # build/NonSleep.app (ad-hoc signed)
scripts/install.sh             # install your build into ~/Applications and run `nonsleep setup`
```

Run the pieces straight from the build directory while iterating:

```sh
.build/debug/nonsleep status
.build/debug/NonSleepBar       # menu bar app without a bundle (no icon, no login item)
```

`nonsleep setup` asks for an administrator password once (sudoers rule for `pmset disablesleep`).
Without it everything still runs, but turning lid-closed mode on fails with a clear error.

## Project layout

| Path | What lives there |
| --- | --- |
| `Sources/NonSleepKit` | everything testable: leases, reconcile engine, power/process inspection, hooks, setup |
| `Sources/nonsleep` | the CLI (`main.swift`) |
| `Sources/NonSleepBar` | SwiftUI menu bar app and management window |
| `Tests/NonSleepKitTests` | swift-testing suites |
| `scripts/` | build, install, test, release-notes, icon generator |
| `.github/workflows` | CI (build, test, universal bundle, shellcheck) and tag-driven releases |

The README's *How it works* section explains the lease model; read it before touching
`NonSleep.apply` or `Lease.isAlive`.

## Guidelines

- **Safety first.** The invariant is: *NonSleep never leaves a machine unable to sleep.* Any change
  to leases, the ownership marker, the reaper, or `apply()` needs a test that would catch a stuck
  flag.
- **Swift 6 strict concurrency, zero warnings.** Don't silence diagnostics with `@unchecked
  Sendable` or `nonisolated(unsafe)` unless you document why it's sound, as the existing uses do.
- **Hooks must never change agent behavior.** `nonsleep hook` always exits 0 and prints only the
  neutral response each agent requires; integrations only add and remove their own entries.
- **Tests** cover behavior a user could notice: lease lifetimes, safety cut-outs, hook decisions,
  config transforms. Use the `FakePower` backend; never call `sudo` or `pmset` from tests.
- Keep the code boring and small. No new dependencies without discussion.
- Shell scripts are POSIX `sh` and must pass `shellcheck`.

## Branching

Always cut from the current `main`, never from another feature or `release/*` branch:

```sh
git checkout main
git pull --ff-only origin main
git checkout -b feat/lid-thermal-retry
```

`release/*` branches exist only to cut a tag. Branching from one puts the release commit in your
PR, and because `main` carries the *squashed* version of that same commit under a different SHA,
GitHub reports a conflict that has nothing to do with your change.

Keep the branch current while you work, and before the final push:

```sh
git fetch origin
git rebase origin/main        # not `git merge main`: keeps the PR a clean list of your commits
```

If `main` already contains a squashed copy of a commit on your branch (you branched from the
wrong place, or kept working on a branch that was already merged), drop it while rebasing instead
of resolving the same hunk by hand:

```sh
git rebase --onto origin/main <last-unwanted-commit>
git push --force-with-lease    # never a bare --force
```

After your PR is squash-merged, delete the branch and start the next one from a fresh `main`.
Continuing on a merged branch reintroduces the mismatched-SHA problem above.

```sh
git checkout main && git pull --ff-only origin main
git branch -D feat/lid-thermal-retry
```

## Pull requests

1. Branch from an up-to-date `main` (see above), keep the change focused.
2. `swift build && scripts/test.sh` pass locally; for app changes, describe what you clicked through.
3. Add an entry under **[Unreleased]** in [CHANGELOG.md](CHANGELOG.md) for user-visible changes.
4. Commit messages: [Conventional Commits](https://www.conventionalcommits.org/) style
   (`fix: …`, `feat: …`, `docs: …`) are appreciated.
5. Every commit should build and pass the suite on its own, so `git bisect` stays useful. Splitting
   a change across commits means splitting its tests and localized strings with it.
6. CI must be green: `macOS · build, test, app bundle`, `Linux · build, test`, and
   `Shell scripts · shellcheck`. A maintainer will review; small follow-ups may be pushed to your
   branch.

## Releasing (maintainers)

1. Move the **[Unreleased]** notes into a new `## [X.Y.Z] - YYYY-MM-DD` section and update the
   compare links at the bottom of `CHANGELOG.md`.
2. Commit, then tag and push: `git tag vX.Y.Z && git push origin main vX.Y.Z`.
3. The *Release* workflow tests, builds the universal app, and publishes a GitHub release with
   `NonSleep-X.Y.Z-macOS.zip`, `SHA256SUMS.txt`, and the changelog section as notes.
   Tags with a suffix (`v1.2.0-beta.1`) become prereleases.
4. Once the release exists, point the Homebrew cask at it and open a PR with the result:
   `scripts/update-cask.sh vX.Y.Z` rewrites `Casks/nonsleep.rb` with the version and the checksum
   taken from that release's `SHA256SUMS.txt`. Copy the file to the `homebrew-tap` repository so
   `brew upgrade --cask nonsleep` picks it up.
5. A release branch (`release/X.Y.Z`) is only a place to prepare the tag. Once it is merged, do
   not branch new work from it — see *Branching*.

By contributing you agree that your contributions are licensed under the [MIT License](LICENSE),
and you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
