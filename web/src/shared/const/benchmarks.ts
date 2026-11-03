export interface BenchmarkMetric {
  label: string;
  value: string;
  highlight: string;
  description: string;
  comparison: string;
}

export const BENCHMARKS: readonly BenchmarkMetric[] = [
  {
    label: "App Bundle Size",
    value: "2.5 MB",
    highlight: "Universal Mach-O",
    description: "Full macOS menu bar app + bundled CLI binary + Retina icons.",
    comparison: "100x smaller than typical Electron apps (150–350 MB)",
  },
  {
    label: "CLI Binary Size",
    value: "452 KB",
    highlight: "Standalone Executable",
    description: "Pure native Swift executable compiled with zero external dependencies.",
    comparison: "Zero runtime dependencies, no Node/Python interpreter required",
  },
  {
    label: "Idle CPU Usage",
    value: "0.0% – 0.1%",
    highlight: "Event-Driven",
    description: "Registers Darwin kernel clamshell callbacks; zero CPU wakeups or busy loops.",
    comparison: "Doesn't drain battery while running in the background",
  },
  {
    label: "CLI Execution Time",
    value: "0.03s",
    highlight: "30 Milliseconds",
    description: "Subcommands (status, reap, on, off) execute in ~30ms and immediately exit.",
    comparison: "0.00s user CPU time, instant terminal responsiveness",
  },
  {
    label: "Resident Memory (RAM)",
    value: "3.9 MB / ~25 MB",
    highlight: "Native AppKit / SwiftUI",
    description: "3.9 MB peak memory for CLI; ~25 MB resident private memory for menu bar app.",
    comparison: "Fraction of memory compared to Electron or Chromium apps (300–800 MB)",
  },
  {
    label: "On-Disk Storage",
    value: "< 10 KB",
    highlight: "Zero Database Bloat",
    description: "Tiny config (~300 B) + ephemeral leases (~150 B) auto-purged on task exit.",
    comparison: "0 SQLite database, 0 log files, 0 persistent junk",
  },
] as const;
