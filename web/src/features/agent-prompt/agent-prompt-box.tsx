"use client";

import * as React from "react";
import { Bot, Copy, Check, Sparkles } from "lucide-react";
import { type Language } from "../../shared/const/content";
import { Card } from "../../shared/ui/card";
import { Button } from "../../shared/ui/button";

export function AgentPromptBox({ lang }: { lang: Language }) {
  const [copied, setCopied] = React.useState(false);

  const promptEn = `Please install and configure NonSleep on my Mac so that my coding agent turns can continue running with the lid closed.
Follow the official steps from https://github.com/Tran-Duc-Duy/nonsleep:
1. Clone and install:
   git clone https://github.com/Tran-Duc-Duy/nonsleep.git && cd nonsleep && scripts/install.sh
2. Connect lifecycle hooks for all agents:
   nonsleep integrate all
3. Run 'nonsleep status' and report the current status to me.`;

  const promptVi = `Hãy cài đặt và cấu hình NonSleep trên máy Mac của tôi để khi gập nắp máy thì agent vẫn tiếp tục cày code bình thường.
Thực hiện theo hướng dẫn từ https://github.com/Tran-Duc-Duy/nonsleep:
1. Clone và cài đặt:
   git clone https://github.com/Tran-Duc-Duy/nonsleep.git && cd nonsleep && scripts/install.sh
2. Tự động kết nối hook cho các agent:
   nonsleep integrate all
3. Chạy 'nonsleep status' và báo cáo lại kết quả cho tôi.`;

  const currentPrompt = lang === "vi" ? promptVi : promptEn;

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(currentPrompt);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback
    }
  };

  return (
    <Card className="border-indigo-200 bg-gradient-to-br from-indigo-50/50 via-white to-white p-4 sm:p-8 shadow-sm">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-4">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-indigo-600 text-white shadow-md shadow-indigo-600/20">
            <Bot className="h-5 w-5" />
          </div>
          <div>
            <h3 className="font-bold text-zinc-900 text-base flex items-center gap-2">
              {lang === "vi" ? "Prompt Sẵn Cho Agent Cài Hộ Bạn" : "Ready-Made Prompt for Your AI Agent"}
              <span className="rounded-full bg-emerald-100 text-emerald-800 border border-emerald-300 px-2 py-0.5 text-[11px] font-bold">
                1-Click Prompt
              </span>
            </h3>
            <p className="text-xs text-zinc-600 mt-0.5">
              {lang === "vi"
                ? "Chỉ cần copy prompt này dán vào Claude Code, Cursor hay Codex, agent sẽ tự cài đặt từ A-Z."
                : "Copy and paste this directly into Claude Code, Cursor, or Codex. Your agent will install and verify everything autonomously."}
            </p>
          </div>
        </div>

        <Button
          variant="primary"
          size="sm"
          onClick={handleCopy}
          className="shrink-0 text-xs"
        >
          {copied ? (
            <>
              <Check className="h-4 w-4 text-emerald-400" />
              <span className="text-emerald-400">Copied Prompt!</span>
            </>
          ) : (
            <>
              <Copy className="h-4 w-4" />
              <span>{lang === "vi" ? "Copy Prompt Cài Hộ" : "Copy Agent Prompt"}</span>
            </>
          )}
        </Button>
      </div>

      <div className="relative rounded-xl border border-zinc-200/90 bg-zinc-50 p-4 font-mono text-xs text-zinc-800 whitespace-pre-wrap leading-relaxed overflow-x-auto shadow-inner">
        {currentPrompt}
      </div>
    </Card>
  );
}
