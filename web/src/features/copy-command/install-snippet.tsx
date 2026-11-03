"use client";

import { Terminal } from "lucide-react";
import { CopyButton } from "./copy-button";
import { cn } from "../../shared/lib/utils";

export interface InstallSnippetProps {
  command: string;
  className?: string;
}

export function InstallSnippet({ command, className }: InstallSnippetProps) {
  return (
    <div
      className={cn(
        "group relative flex items-center justify-between rounded-xl border border-zinc-200/90 bg-white px-4 py-3 font-mono text-xs sm:text-sm text-zinc-900 shadow-[0_2px_12px_-3px_rgba(0,0,0,0.05)]",
        className
      )}
    >
      <div className="flex items-center gap-3 overflow-x-auto pr-2 scrollbar-none">
        <Terminal className="h-4 w-4 shrink-0 text-indigo-600" />
        <span className="text-zinc-400 select-none font-bold">$</span>
        <code className="whitespace-nowrap font-medium">{command}</code>
      </div>
      <CopyButton textToCopy={command} className="shrink-0" />
    </div>
  );
}
