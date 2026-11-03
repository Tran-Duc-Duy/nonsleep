const REPO = "https://github.com/Tran-Duc-Duy/nonsleep";

/// The one place a release version is written on the web side. Everything that needs it —
/// download URLs, the hero pill, the attestation example, the simulated app chrome — reads it
/// from here. It used to appear verbatim in nine files, which is how a release ends up half
/// bumped.
const VERSION = "0.3.0";
const TAG = `v${VERSION}`;
const RELEASE = `${REPO}/releases/download/${TAG}`;

export const SITE_CONFIG = {
  name: "NonSleep",
  shortName: "NonSleep",
  title: "NonSleep — Keep your Mac awake with the lid closed for AI Coding Agents",
  description:
    "The open-source, agent-aware power management tool for macOS. Keep your MacBook working with the lid closed while Claude Code, Cursor, Codex, and omp run — and sleep automatically the moment they finish.",
  /// The site's own origin — never the repo URL. It is the canonical/OG/sitemap base, so
  /// pointing it at GitHub told search engines the canonical copy of every page lived there.
  /// Override at deploy time to move to a custom domain without touching code.
  url: process.env.NEXT_PUBLIC_SITE_URL ?? "https://nonsleep.vercel.app",
  author: "Tran Duc Duy",
  githubUrl: REPO,
  releasesUrl: `${REPO}/releases`,
  version: VERSION,
  latestVersion: TAG,
  latestReleaseDate: "2026-11-04",
  downloadMacUrl: `${RELEASE}/NonSleep-${VERSION}-macOS.zip`,
  downloadLinuxX64Url: `${RELEASE}/nonsleep-${VERSION}-linux-x86_64.tar.gz`,
  downloadLinuxArmUrl: `${RELEASE}/nonsleep-${VERSION}-linux-aarch64.tar.gz`,
  macArtifactName: `NonSleep-${VERSION}-macOS.zip`,
  installCommand: `git clone ${REPO}.git && cd nonsleep && scripts/install.sh`,
  quickIntegrateCommand: "nonsleep integrate all",
  license: "MIT",
  keywords: [
    "macbook lid closed",
    "keep mac awake closed lid",
    "clamshell mode without monitor",
    "claude code lid closed",
    "cursor ai keep awake",
    "codex cli keep awake",
    "caffeinate alternative",
    "pmset disablesleep",
    "ai coding agents",
    "macos power management",
    "sleep when done",
    "nonsleep",
  ],
} as const;
