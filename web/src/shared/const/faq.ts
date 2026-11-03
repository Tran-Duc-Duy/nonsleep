export interface FaqItem {
  id: string;
  question: string;
  answer: string;
  category: "General" | "Security" | "Usage" | "Comparison";
}

export const FAQS: readonly FaqItem[] = [
  {
    id: "how-clamshell-works",
    question: "How does NonSleep keep my MacBook awake when the lid is closed?",
    answer:
      "Standard tools like caffeinate rely on IOPMAssertion, which macOS ignores when the lid closes without an external display connected. NonSleep controls the system flag `pmset -a disablesleep 1`, which is the only switch macOS respects when the lid is shut. NonSleep binds this flag to time-limited, process-monitored leases so the machine always returns to normal sleep when work finishes.",
    category: "General",
  },
  {
    id: "listen-youtube-music",
    question: "Can I use NonSleep to listen to YouTube or podcasts with the lid closed?",
    answer:
      "Yes! Simply click 'Custom…' in the menu bar app and enter a timer (e.g. `45m` or `2h`), or run `nonsleep on 45m` in your terminal. You can close your MacBook and enjoy audio playback; your Mac will automatically go to sleep when the timer expires or if the battery drops below 20%.",
    category: "Usage",
  },
  {
    id: "why-gatekeeper-warning",
    question: "Why does macOS Gatekeeper show an 'unverified developer' prompt on first launch?",
    answer:
      "NonSleep is a free, independent open-source project. Apple charges a $99/year developer fee to notarize binaries with an Apple Developer ticket. Without it, macOS flags all ad-hoc signed apps by default. You can bypass this with one click in System Settings › Privacy & Security › Open Anyway, or verify the cryptographic build provenance via `gh attestation verify`.",
    category: "Security",
  },
  {
    id: "sudo-safety-root",
    question: "Why does setup ask for an administrator password, and is it safe?",
    answer:
      "Setting `pmset -a disablesleep` requires root. Rather than running a background root daemon (which would be a massive security risk), NonSleep installs a tightly scoped one-line rule in `/etc/sudoers.d/nonsleep` allowing ONLY `/usr/bin/pmset -a disablesleep 0` and `1`. It cannot run any other command as root. The installation is protected against TOCTOU race conditions by staging into root storage before `visudo -c` validation.",
    category: "Security",
  },
  {
    id: "privacy-and-logs",
    question: "Does NonSleep collect telemetry or read my agent prompts?",
    answer:
      "No. NonSleep contains zero network code (no URLSession, no sockets, no telemetry). It runs 100% offline, which you can verify with `lsof -p $(pgrep NonSleepBar) -i` (returns empty). Agent hooks only send lifecycle signals (`UserPromptSubmit`, `Stop`); NonSleep never reads prompt text, code, or tokens.",
    category: "Security",
  },
  {
    id: "backpack-overheating",
    question: "Will my MacBook overheat in my backpack if I leave a task running?",
    answer:
      "NonSleep includes built-in hardware safety cut-outs: if macOS reports a 'serious' or 'critical' thermal state, or if battery drops below 20%, NonSleep immediately drops the sleep block and puts the Mac to sleep. However, as good practice, we recommend not running heavy rendering inside a closed insulated backpack.",
    category: "Usage",
  },
  {
    id: "difference-amphetamine",
    question: "How is NonSleep different from Amphetamine or Caffeinate?",
    answer:
      "Amphetamine and Caffeinate are designed to keep the screen from turning off while the laptop is open on your desk. When you close the lid without an external monitor, they cannot prevent sleep. NonSleep is designed specifically for closed-lid (clamshell) operation and integrates directly with AI agent turn lifecycles.",
    category: "Comparison",
  },
] as const;
