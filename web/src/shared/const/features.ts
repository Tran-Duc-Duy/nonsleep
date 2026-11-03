export interface FeatureItem {
  id: string;
  badge: string;
  title: string;
  tagline: string;
  description: string;
  technicalDetails: string;
  iconName: "Laptop" | "Bot" | "ShieldCheck" | "Lock" | "Gauge" | "HeartPulse";
}

export const FEATURES: readonly FeatureItem[] = [
  {
    id: "clamshell-no-display",
    badge: "Core Architecture",
    title: "True Clamshell Mode Without External Monitor",
    tagline: "Close the lid, pack your bag, or step away. Tasks keep running.",
    description:
      "Unlike caffeinate or Amphetamine which only block idle sleep, NonSleep manages the system flag pmset disablesleep 1, allowing your Mac to work with the lid shut completely.",
    technicalDetails:
      "Overrides Darwin root-domain clamshell sleep without requiring a dummy HDMI plug or external power adapter.",
    iconName: "Laptop",
  },
  {
    id: "agent-aware",
    badge: "AI-First",
    title: "Agent-Aware Lifecycle: Sleep The Moment Work Finishes",
    tagline: "Never guess when a turn finishes. Never leave a Mac permanently awake.",
    description:
      "NonSleep hooks into Claude Code, Cursor, Codex, and Antigravity, and monitors omp power assertions. It holds the Mac awake while prompts are in flight and releases sleep when done.",
    technicalDetails:
      "Subscribes to turn lifecycle hooks (UserPromptSubmit, PreInvocation, Stop, SessionEnd) and reads IOPM power assertions.",
    iconName: "Bot",
  },
  {
    id: "fail-safe-lease",
    badge: "Zero-Risk Engine",
    title: "Ephemeral Lease & Automatic LaunchAgent Reaper",
    tagline: "Crash, kill -9, or sudden reboot: your Mac always returns to normal sleep.",
    description:
      "Every keep-awake request is a lease tied to a process ID, current boot session, and TTL timeout. A background LaunchAgent sweeps dead leases every 60 seconds.",
    technicalDetails:
      "Process start-time validation protects against PID reuse attacks. Pure file-based atomicity with zero database bloat.",
    iconName: "HeartPulse",
  },
  {
    id: "privacy-lock",
    badge: "Security",
    title: "Automatic Session Lock On Lid Close",
    tagline: "Tasks keep running, but your screen is locked tight against prying eyes.",
    description:
      "When closing the lid, NonSleep automatically powers off the displays, prompting macOS to lock the session immediately with Touch ID or password.",
    technicalDetails:
      "Invokes pmset displaysleepnow (macOS) or loginctl lock-session (Linux) immediately upon clamshell close.",
    iconName: "Lock",
  },
  {
    id: "hardware-safeguards",
    badge: "Battery & Thermal",
    title: "Hardware Cut-Outs: Battery & Thermal Protection",
    tagline: "Prevents battery drain to 0% and eliminates backpack overheating risks.",
    description:
      "NonSleep continuously monitors battery level and thermal pressure. If battery drops below 20% or thermal state turns serious/critical, it halts sleep inhibition instantly.",
    technicalDetails:
      "Reads IOKit.ps power source updates and ProcessInfo.thermalState with customizable thresholds.",
    iconName: "ShieldCheck",
  },
  {
    id: "native-performance",
    badge: "Performance",
    title: "Native Swift: 2.5 MB App, 452 KB CLI, 0.0% Idle CPU",
    tagline: "No Electron. No Node.js. No background polling loops.",
    description:
      "Compiled into native Mach-O universal binaries. Starts in 30ms, consumes just ~25MB RAM in menu bar, and uses 0.0% CPU when idle.",
    technicalDetails:
      "Event-driven through Darwin notifications and IOKit callbacks rather than wasteful polling timers.",
    iconName: "Gauge",
  },
] as const;
