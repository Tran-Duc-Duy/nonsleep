"use client";

import * as React from "react";
import { Moon, Lock, ShieldCheck, Activity, Terminal, Battery, Wifi, Sparkles, Laptop } from "lucide-react";
import { type Language } from "../../shared/const/content";
import { SITE_CONFIG } from "../../shared/const/site-config";
import { LottiePlayer } from "../../shared/ui/lottie-player";
import { Button } from "../../shared/ui/button";
import pulseGlow from "../../shared/assets/lottie/pulse-glow.json";

export function MacbookMockup({ lang }: { lang: Language }) {
  const [step, setStep] = React.useState<1 | 2 | 3>(2);

  const steps = [
    {
      id: 1,
      label: lang === "vi" ? "1. Gõ Prompt (Mở máy)" : "1. Prompt In Flight",
      sub: lang === "vi" ? "Agent bắt đầu cày" : "Lid Open · Working",
      icon: Laptop,
    },
    {
      id: 2,
      label: lang === "vi" ? "2. Gập nắp máy" : "2. Shut MacBook Lid",
      sub: lang === "vi" ? "NonSleep giữ máy cày" : "Clamshell · Holding",
      icon: Lock,
    },
    {
      id: 3,
      label: lang === "vi" ? "3. Xong việc tự ngủ" : "3. Turn Completed",
      sub: lang === "vi" ? "Nhả cờ · Mac đi ngủ" : "Auto-Sleeps · Zzz",
      icon: Moon,
    },
  ];

  return (
    // On phones the outer card is dropped entirely: it wrapped a macOS-window card that wrapped
    // a panel card that wrapped a lease card — four nested borders in a 393px column.
    <div className="w-full max-w-4xl mx-auto text-left rounded-none sm:rounded-3xl border-0 sm:border sm:border-black/[0.08] bg-transparent sm:bg-white p-0 sm:p-8 sm:shadow-[0_4px_25px_-5px_rgba(0,0,0,0.06)]">
      <div className="grid grid-cols-3 gap-1 sm:gap-2 p-1 sm:p-1.5 rounded-2xl bg-[#f5f5f7] border border-black/[0.06] mb-4 sm:mb-8">
        {steps.map((s) => {
          const Icon = s.icon;
          const isActive = step === s.id;
          return (
            <Button
              key={s.id}
              variant="segmented"
              size="xs"
              selected={isActive}
              onClick={() => setStep(s.id as 1 | 2 | 3)}
              className="h-auto flex-col sm:flex-row gap-1 sm:gap-2.5 rounded-xl px-1.5 py-2 sm:px-2 sm:py-2.5 text-center"
            >
              <div
                className={`flex h-6 w-6 shrink-0 items-center justify-center rounded-lg ${
                  isActive
                    ? s.id === 2
                      ? "bg-emerald-500 text-white"
                      : "bg-[#1d1d1f] text-white"
                    : "bg-zinc-200 text-zinc-600"
                }`}
              >
                <Icon className="h-3.5 w-3.5" />
              </div>
              <div className="min-w-0">
                <span className="block text-[11px] sm:text-sm leading-tight">{s.label}</span>
                <span className="hidden md:block text-[11px] text-[#6e6e73] font-normal">
                  {s.sub}
                </span>
              </div>
            </Button>
          );
        })}
      </div>

      {/* Simulated macOS Desktop Window */}
      <div className="rounded-2xl border border-black/[0.08] bg-[#fbfbfd] overflow-hidden shadow-sm">
        {/* macOS Menu Bar */}
        <div className="flex items-center justify-between border-b border-black/[0.06] bg-white px-4 py-2.5 text-xs text-[#1d1d1f] select-none">
          <div className="flex items-center gap-4 font-medium">
            <span className="font-bold text-sm"></span>
            <span className="font-semibold">NonSleep</span>
            <span className="hidden sm:inline text-[#6e6e73]">File</span>
            <span className="hidden sm:inline text-[#6e6e73]">Edit</span>
            <span className="hidden sm:inline text-[#6e6e73]">View</span>
            <span className="hidden sm:inline text-[#6e6e73]">Help</span>
          </div>

          <div className="flex items-center gap-3 font-mono text-[11px] text-[#6e6e73]">
            {/* NonSleep Menu Bar Icon */}
            <div className="flex items-center gap-1.5 rounded-md bg-[#f5f5f7] border border-black/[0.06] px-2 py-0.5">
              {step === 2 ? (
                <>
                  <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                  <span className="font-bold text-emerald-700">NonSleep: Active</span>
                </>
              ) : step === 3 ? (
                <>
                  <Moon className="h-3 w-3 text-zinc-500" />
                  <span className="text-zinc-600">Sleeping</span>
                </>
              ) : (
                <>
                  <Activity className="h-3 w-3 text-indigo-600" />
                  <span className="text-indigo-700">Open · Watching</span>
                </>
              )}
            </div>
            <Wifi className="h-3.5 w-3.5 text-[#6e6e73]" />
            <div className="flex items-center gap-1">
              <Battery className="h-3.5 w-3.5 text-[#1d1d1f]" />
              <span>84%</span>
            </div>
            <span className="font-sans font-medium text-[#1d1d1f]">17:45</span>
          </div>
        </div>

        {/* Dual-Panel Workspace: Left = NonSleep HUD, Right = Live Terminal */}
        <div className="p-3 sm:p-5 grid grid-cols-1 md:grid-cols-12 gap-3 sm:gap-5">
          {/* Left panel: no card chrome on phones — it already sits inside the window frame. */}
          <div className="md:col-span-5 rounded-none md:rounded-2xl border-0 md:border md:border-black/[0.08] bg-transparent md:bg-white p-0 md:p-5 md:shadow-sm flex flex-col justify-between space-y-4">
            <div>
              {/* App Status Header */}
              <div className="flex items-center gap-3 pb-3 border-b border-black/[0.06]">
                <div className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-indigo-50 border border-indigo-100 text-indigo-600 shadow-sm">
                  {step === 2 && (
                    <div className="absolute inset-0 flex items-center justify-center pointer-events-none scale-125 opacity-70">
                      <LottiePlayer animationData={pulseGlow} className="w-full h-full" />
                    </div>
                  )}
                  {step === 2 ? (
                    <Activity className="h-5 w-5 text-emerald-600 relative z-10 animate-pulse" />
                  ) : step === 3 ? (
                    <Moon className="h-5 w-5 text-zinc-500" />
                  ) : (
                    <Sparkles className="h-5 w-5 text-indigo-600" />
                  )}
                </div>
                <div>
                  {/* Simulated app UI, not a document heading: as an <h3> directly under the
                      hero's <h1> it broke the heading order for screen readers. */}
                  <p className="font-bold text-[#1d1d1f] text-sm leading-tight">
                    {step === 1 && "Watching Agent Activity"}
                    {step === 2 && "Stays awake with lid closed"}
                    {step === 3 && "Normal sleep restored"}
                  </p>
                  <p className="text-[11px] text-[#6e6e73] mt-0.5">
                    {step === 1 && "Lid open · Battery 84%"}
                    {step === 2 && "Lid closed · Battery 84% · Clamshell"}
                    {step === 3 && "Lid closed · Machine asleep"}
                  </p>
                </div>
              </div>

              {/* Active Leases List */}
              <div className="pt-3 space-y-2">
                <span className="text-[11px] font-bold uppercase tracking-wider text-[#6e6e73]">
                  Active Leases
                </span>
                {step === 1 && (
                  <div className="rounded-xl bg-[#f5f5f7] border border-black/[0.04] p-2.5 text-xs">
                    <p className="font-semibold text-[#1d1d1f]">Claude Code · my-app</p>
                    <p className="text-[11px] text-[#6e6e73]">pid 48291 · UserPromptSubmit</p>
                  </div>
                )}
                {step === 2 && (
                  <div className="rounded-xl bg-emerald-50/80 border border-emerald-200/80 p-2.5 text-xs space-y-1">
                    <div className="flex items-center justify-between">
                      <p className="font-bold text-emerald-900">Claude Code · my-app</p>
                      <span className="h-2 w-2 rounded-full bg-emerald-500 animate-ping" />
                    </div>
                    <p className="text-[11px] text-emerald-700">pid 48291 · Holding until 18:15</p>
                  </div>
                )}
                {step === 3 && (
                  <div className="rounded-xl bg-[#f5f5f7] p-3 text-center text-xs text-[#6e6e73]">
                    No active leases. Mac is sleeping as usual.
                  </div>
                )}
              </div>
            </div>

            {/* Hardware Status Strip */}
            <div className="pt-3 border-t border-black/[0.06] text-[11px] text-[#6e6e73] space-y-1.5">
              <div className="flex items-center justify-between">
                <span>Display Lock:</span>
                <span className="font-semibold text-[#1d1d1f]">
                  {step === 1 ? "Unlocked" : "Locked (Touch ID)"}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span>Thermal State:</span>
                <span className="text-emerald-700 font-medium">38°C (Nominal)</span>
              </div>
              <div className="flex items-center justify-between">
                <span>Battery Cut-out:</span>
                <span className="text-emerald-700 font-medium">&lt;20% triggers sleep</span>
              </div>
            </div>
          </div>

          {/* Right Panel: Authentic Dark Mac Terminal Window (7 cols) */}
          <div className="md:col-span-7 rounded-2xl border border-zinc-800 bg-[#0c0d10] p-4 shadow-md font-mono text-xs flex flex-col justify-between min-h-[280px]">
            {/* Terminal Titlebar */}
            <div className="flex items-center justify-between pb-3 border-b border-zinc-800/80">
              <div className="flex items-center gap-1.5">
                <span className="h-2.5 w-2.5 rounded-full bg-rose-500/80" />
                <span className="h-2.5 w-2.5 rounded-full bg-amber-500/80" />
                <span className="h-2.5 w-2.5 rounded-full bg-emerald-500/80" />
              </div>
              <span className="text-[11px] text-zinc-400">claude-code — 80x24</span>
              <div className="w-8" />
            </div>

            {/* Terminal Output Stream */}
            <div className="py-3 space-y-2 flex-1 text-zinc-300">
              <div className="flex items-center gap-2">
                <span className="text-emerald-400 select-none">~</span>
                <span className="text-zinc-500 select-none">$</span>
                <span className="text-white font-semibold">
                  claude --task &quot;Refactor auth &amp; migrate DB&quot;
                </span>
              </div>

              {step === 1 && (
                <div className="space-y-1.5 text-zinc-400 pt-2">
                  <p className="text-indigo-400">&gt; Starting turn across 24 files...</p>
                  <p className="text-zinc-300">[1/20] Analyzing schema.prisma</p>
                  <p className="text-zinc-400">[2/20] Updating JWT verification flow...</p>
                  <p className="text-amber-400 animate-pulse-legible">Running step 3 of 20 (Lid open)...</p>
                </div>
              )}

              {step === 2 && (
                <div className="space-y-1.5 text-zinc-300 pt-2">
                  <p className="text-emerald-400 font-bold">
                    [NonSleep] Clamshell closed! pmset disablesleep 1 active.
                  </p>
                  <p className="text-zinc-400">[NonSleep] Displays powered off. Session locked.</p>
                  <p className="text-zinc-300">[12/20] Writing unit tests for token expiry...</p>
                  <p className="text-emerald-400">[Test: OK] 18 tests passing in background</p>
                  <p className="text-indigo-300 animate-pulse-legible">
                    Step 19/20 compiling with lid shut...
                  </p>
                </div>
              )}

              {step === 3 && (
                <div className="space-y-1.5 text-zinc-400 pt-2">
                  <p className="text-emerald-400">[20/20] Refactor complete. Git commit created.</p>
                  <p className="text-indigo-400">&gt; Claude finished turn. Emitted Stop hook.</p>
                  <p className="text-zinc-300 font-bold">
                    [NonSleep] Stop hook detected. Releasing sleep lease.
                  </p>
                  <p className="text-zinc-500">
                    [NonSleep] pmset disablesleep 0. Mac sleeping now (0% battery wasted).
                  </p>
                </div>
              )}
            </div>

            {/* Terminal Footer */}
            <div className="pt-2 border-t border-zinc-800/60 text-[11px] text-zinc-400 flex items-center justify-between">
              <span>Status: {step === 2 ? "Clamshell Task Active" : step === 3 ? "Process Exited (0)" : "Interactive"}</span>
              <span className="text-zinc-400">NonSleep Engine {SITE_CONFIG.latestVersion}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
