export interface ComparisonRow {
  capability: string;
  nonSleep: boolean | string;
  amphetamine: boolean | string;
  caffeinate: boolean | string;
  agentCaffeine: boolean | string;
  amped: boolean | string;
  note: string;
}

export const COMPARISON_DATA: readonly ComparisonRow[] = [
  {
    capability: "Close lid without external monitor",
    nonSleep: true,
    amphetamine: "Needs monitor/power",
    caffeinate: false,
    agentCaffeine: true,
    amped: true,
    note: "NonSleep uses pmset disablesleep 1, allowing true standalone clamshell mode.",
  },
  {
    capability: "Auto-sleep when AI agent finishes",
    nonSleep: true,
    amphetamine: false,
    caffeinate: false,
    agentCaffeine: true,
    amped: false,
    note: "NonSleep hooks into Claude, Cursor, Codex, and omp; auto-sleeps on turn completion.",
  },
  {
    capability: "Custom timer (e.g. 45m for YouTube)",
    nonSleep: true,
    amphetamine: true,
    caffeinate: "CLI only",
    agentCaffeine: false,
    amped: false,
    note: "GUI allows typing custom duration like 45m or 2h with automatic sleep when done.",
  },
  {
    capability: "Auto-lock screen on lid close",
    nonSleep: true,
    amphetamine: false,
    caffeinate: false,
    agentCaffeine: true,
    amped: true,
    note: "Displays are turned off on clamshell close, enforcing macOS password/TouchID lock.",
  },
  {
    capability: "Thermal & Low Battery Cut-outs",
    nonSleep: "Auto (<20% or Hot)",
    amphetamine: "Battery % only",
    caffeinate: false,
    agentCaffeine: true,
    amped: "Battery only",
    note: "Protects against battery drain to 0% and backpack heat build-up.",
  },
  {
    capability: "Zero Background Root Daemon",
    nonSleep: true,
    amphetamine: true,
    caffeinate: true,
    agentCaffeine: false,
    amped: false,
    note: "NonSleep uses a tightly scoped sudoers rule for pmset only. No root daemon.",
  },
  {
    capability: "Zero Telemetry (No Background Network)",
    nonSleep: true,
    amphetamine: false,
    caffeinate: true,
    agentCaffeine: "Closed-source",
    amped: true,
    note: "NonSleep sends nothing on its own; the only request is the update button you press.",
  },
  {
    capability: "Open Source & Verifiable (SLSA)",
    nonSleep: "MIT + SLSA Provenance",
    amphetamine: "Proprietary",
    caffeinate: "Apple Built-in",
    agentCaffeine: "Proprietary",
    amped: "GPL-3.0",
    note: "Every release is cryptographically signed and verified via GitHub Artifact Attestations.",
  },
  {
    capability: "Memory Footprint",
    nonSleep: "~25 MB RAM (3.9 MB CLI)",
    amphetamine: "~40 MB",
    caffeinate: "< 5 MB",
    agentCaffeine: "~70 MB",
    amped: "~30 MB",
    note: "Pure Swift AppKit/SwiftUI native compilation. Zero Electron overhead.",
  },
] as const;
