"use client";

import * as React from "react";
import { Terminal, Circle, Check, Copy } from "lucide-react";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";
import { Button } from "../../shared/ui/button";

interface TabCommand {
  id: string;
  label: string;
  command: string;
  output: string[];
}

const DEMO_TABS: TabCommand[] = [
  {
    id: "status",
    label: "Status & Inspection",
    command: "nonsleep status",
    output: [
      "Stays awake with the lid closed",
      "  lid closed · battery power · battery 84% · thermal nominal",
      "leases:",
      "  Claude Code · my-app  (pid 48291, until 19:42)",
      "  Auto: agents working  (pid 5085)",
      "agents: claude · pid 48291",
    ],
  },
  {
    id: "run",
    label: "One-Off Command Run",
    command: "nonsleep run -- npx my-long-agent-task",
    output: [
      "[17:15:02] NonSleep lease acquired: 'run: npx my-long-agent-task'",
      "Running multi-step agent prompt with lid closed...",
      "==> Task completed successfully (exit 0)",
      "[17:42:19] Releasing sleep lease. Putting MacBook to sleep now.",
    ],
  },
  {
    id: "timer",
    label: "Custom Sleep Timer (YouTube)",
    command: "nonsleep on 45m",
    output: [
      "Holding lease: 'Manual until 18:00' (45 minutes)",
      "Clamshell audio playback active (displays turned off & locked)",
      "Mac will automatically sleep at 18:00 or if battery < 20%",
    ],
  },
  {
    id: "integrate",
    label: "1-Click Agent Setup",
    command: "nonsleep integrate all",
    output: [
      "omp: built in (power assertion 'omp agent session')",
      "Claude Code: installed (hooks configured in ~/.claude/settings.json)",
      "Cursor: installed (hooks configured in ~/.cursor/hooks.json)",
      "OpenAI Codex: installed (hooks configured in ~/.codex/hooks.json)",
      "Antigravity: installed (hooks configured in ~/.gemini/config/hooks.json)",
    ],
  },
];

export function TerminalDemo() {
  const [activeTab, setActiveTab] = React.useState(DEMO_TABS[0]!.id);
  const [copied, setCopied] = React.useState(false);
  const currentDemo = DEMO_TABS.find((t) => t.id === activeTab) ?? DEMO_TABS[0]!;

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(currentDemo.command);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback
    }
  };

  return (
    <section className="py-20 border-t border-zinc-200/80 bg-zinc-50/60">
      <Container>
        <SectionHeading
          badge="Interactive Preview"
          title="Designed for Terminal & Automation"
          subtitle="One engine shared between the Menu Bar app and the CLI. Predictable, scriptable, and transparent."
        />

        <div className="mx-auto max-w-4xl">
          {/* Terminal Tabs */}
          <div className="flex flex-wrap items-center gap-2 mb-3">
            {DEMO_TABS.map((tab) => (
              <Button
                key={tab.id}
                variant="chip"
                size="xs"
                selected={activeTab === tab.id}
                onClick={() => {
                  setActiveTab(tab.id);
                  setCopied(false);
                }}
                className={activeTab === tab.id ? "border-zinc-900 bg-zinc-900" : undefined}
              >
                {tab.label}
              </Button>
            ))}
          </div>

          {/* Terminal Window with High-End Dark Contrast */}
          <div className="rounded-2xl border border-zinc-800 bg-[#0c0d10] shadow-[0_12px_40px_-10px_rgba(0,0,0,0.25)] overflow-hidden font-mono text-xs sm:text-sm">
            {/* Window titlebar with Copy Button */}
            <div className="flex items-center justify-between border-b border-zinc-800/80 bg-zinc-900/90 px-4 py-3">
              <div className="flex items-center gap-2">
                <Circle className="h-3 w-3 fill-rose-500/90 text-rose-500/90" />
                <Circle className="h-3 w-3 fill-amber-500/90 text-amber-500/90" />
                <Circle className="h-3 w-3 fill-emerald-500/90 text-emerald-500/90" />
              </div>
              <div className="text-zinc-400 text-xs flex items-center gap-1.5 font-medium">
                <Terminal className="h-3.5 w-3.5 text-indigo-400" />
                <span>nonsleep — zsh</span>
              </div>
              
              {/* Prominent Copy Button in Titlebar */}
              <Button
                variant="ghost"
                size="xs"
                onClick={handleCopy}
                className="rounded-lg border border-zinc-700 bg-zinc-800/80 text-zinc-300 hover:bg-zinc-700 hover:text-white"
              >
                {copied ? (
                  <>
                    <Check className="h-3.5 w-3.5 text-emerald-400" />
                    <span className="text-emerald-400 font-semibold">Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy className="h-3.5 w-3.5" />
                    <span>Copy command</span>
                  </>
                )}
              </Button>
            </div>

            {/* Terminal Body */}
            <div className="p-5 space-y-3 min-h-[220px]">
              <div className="flex items-center justify-between gap-3 pb-2 border-b border-zinc-800/80">
                <div className="flex items-center gap-2 text-zinc-300 overflow-x-auto scrollbar-none">
                  <span className="text-emerald-400 select-none">~</span>
                  <span className="text-zinc-500 select-none">$</span>
                  <span className="text-white font-semibold whitespace-nowrap">
                    {currentDemo.command}
                  </span>
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={handleCopy}
                  className="border-0 bg-transparent text-zinc-400 hover:bg-zinc-800 hover:text-white"
                  aria-label="Copy command"
                >
                  {copied ? (
                    <Check className="h-4 w-4 text-emerald-400" />
                  ) : (
                    <Copy className="h-4 w-4" />
                  )}
                </Button>
              </div>

              <div className="space-y-1.5 pt-2 text-zinc-400">
                {currentDemo.output.map((line, idx) => (
                  <div key={idx} className="leading-relaxed">
                    {line}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </Container>
    </section>
  );
}
