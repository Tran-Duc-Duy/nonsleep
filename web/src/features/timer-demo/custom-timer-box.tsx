"use client";

import * as React from "react";
import { Timer, Play, ShieldAlert, Sparkles, Moon } from "lucide-react";
import { Button } from "../../shared/ui/button";
import { Card } from "../../shared/ui/card";

export function CustomTimerBox() {
  const [input, setInput] = React.useState("45m");
  const [activeTimer, setActiveTimer] = React.useState<string | null>("45m");
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  const parseToMinutes = (val: string): number => {
    const trimmed = val.trim().toLowerCase();
    if (trimmed.endsWith("h")) return parseFloat(trimmed) * 60 || 60;
    if (trimmed.endsWith("m")) return parseFloat(trimmed) || 45;
    if (trimmed.includes("h") && trimmed.includes("m")) {
      const parts = trimmed.split("h");
      const h = parseFloat(parts[0] || "0") * 60;
      const m = parseFloat(parts[1]?.replace("m", "") || "0");
      return h + m || 90;
    }
    return parseFloat(trimmed) || 45;
  };

  const minutes = parseToMinutes(input);

  const getEstimatedSleepTime = (): string => {
    if (!mounted) return `+${minutes}m`;
    const now = new Date();
    now.setMinutes(now.getMinutes() + minutes);
    return now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  return (
    <Card className="border-indigo-200 bg-gradient-to-br from-indigo-50/40 via-white to-white p-6 sm:p-8 shadow-sm">
      <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 mb-6">
        <div className="flex items-center gap-2.5">
          <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-indigo-50 border border-indigo-200 text-indigo-600 shadow-sm">
            <Timer className="h-5 w-5" />
          </div>
          <div>
            <h3 className="font-bold text-zinc-900 text-base">Interactive Sleep Timer Simulator</h3>
            <p className="text-xs text-zinc-600 mt-0.5">
              For YouTube, podcasts, audiobooks, or long compilation tasks.
            </p>
          </div>
        </div>
        <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-100 text-emerald-800 border border-emerald-300 px-3 py-1 text-xs font-semibold font-mono">
          <Sparkles className="h-3.5 w-3.5 text-emerald-600" />
          Native Feature in v0.2.0
        </span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-center">
        <div className="space-y-4">
          <div>
            <label
              htmlFor="custom-timer-duration"
              className="block text-xs font-medium text-zinc-700 mb-1.5"
            >
              Enter any duration format:
            </label>
            <div className="flex items-center gap-2">
              <input
                id="custom-timer-duration"
                name="duration"
                type="text"
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="e.g. 45m, 2h, 1h30m, 90m"
                className="w-full rounded-xl border border-zinc-300 bg-white px-3.5 py-2.5 text-sm font-mono text-zinc-900 placeholder-zinc-400 focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 focus:outline-none shadow-sm"
              />
              <Button
                variant="primary"
                size="md"
                onClick={() => setActiveTimer(input)}
                className="shrink-0"
              >
                <Play className="h-4 w-4 mr-1 fill-current" />
                Simulate
              </Button>
            </div>
          </div>

          <div className="flex flex-wrap gap-2 text-xs">
            <span className="text-zinc-500 self-center font-medium">Presets:</span>
            {["30m", "45m", "1h30m", "2h", "3h"].map((p) => (
              <Button
                key={p}
                variant="chip"
                size="xs"
                selected={input === p}
                onClick={() => {
                  setInput(p);
                  setActiveTimer(p);
                }}
                className="rounded-lg font-mono"
              >
                {p}
              </Button>
            ))}
          </div>
        </div>

        <div className="rounded-2xl border border-zinc-200/90 bg-zinc-50/80 p-5 font-mono text-xs space-y-2.5 shadow-inner">
          <div className="flex items-center justify-between text-zinc-600 border-b border-zinc-200 pb-2">
            <span className="font-semibold text-zinc-800">Simulated System State</span>
            <span className="text-emerald-700 font-bold flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              Lid Closed &amp; Playing Audio
            </span>
          </div>
          <div className="text-zinc-800" suppressHydrationWarning>
            <span className="text-zinc-500">Lease:</span> Manual until{" "}
            <span className="font-semibold" suppressHydrationWarning>{getEstimatedSleepTime()}</span> ({minutes} min)
          </div>
          <div className="text-zinc-800">
            <span className="text-zinc-500">Flag:</span> pmset -a disablesleep 1 (managed)
          </div>
          <div className="text-zinc-800">
            <span className="text-zinc-500">Display:</span> Turned off (session locked)
          </div>
          <div className="flex items-center justify-between text-[11px] text-zinc-600 pt-1.5 border-t border-zinc-200" suppressHydrationWarning>
            <span className="flex items-center gap-1 text-indigo-700 font-medium">
              <Moon className="h-3.5 w-3.5 text-indigo-600" />
              Mac sleeps automatically at{" "}
              <span suppressHydrationWarning>{getEstimatedSleepTime()}</span>
            </span>
            <span className="flex items-center gap-1 text-amber-700 font-medium">
              <ShieldAlert className="h-3.5 w-3.5 text-amber-600" />
              Auto-cutoff if battery &lt; 20%
            </span>
          </div>
        </div>
      </div>
    </Card>
  );
}
