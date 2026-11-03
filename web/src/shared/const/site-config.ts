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
  githubUrl: "https://github.com/Tran-Duc-Duy/nonsleep",
  releasesUrl: "https://github.com/Tran-Duc-Duy/nonsleep/releases",
  latestVersion: "v0.2.0",
  latestReleaseDate: "2026-11-02",
  downloadMacUrl:
    "https://github.com/Tran-Duc-Duy/nonsleep/releases/download/v0.2.0/NonSleep-0.2.0-macOS.zip",
  downloadLinuxX64Url:
    "https://github.com/Tran-Duc-Duy/nonsleep/releases/download/v0.2.0/nonsleep-0.2.0-linux-x86_64.tar.gz",
  downloadLinuxArmUrl:
    "https://github.com/Tran-Duc-Duy/nonsleep/releases/download/v0.2.0/nonsleep-0.2.0-linux-aarch64.tar.gz",
  installCommand:
    "git clone https://github.com/Tran-Duc-Duy/nonsleep.git && cd nonsleep && scripts/install.sh",
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
