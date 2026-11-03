"use client";

import * as React from "react";
import { Check, Copy } from "lucide-react";
import { Button } from "../../shared/ui/button";
import { cn } from "../../shared/lib/utils";

export interface CopyButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  textToCopy: string;
}

export function CopyButton({ textToCopy, className, ...props }: CopyButtonProps) {
  const [copied, setCopied] = React.useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(textToCopy);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback
    }
  };

  return (
    <Button
      variant="outline"
      size="icon"
      onClick={handleCopy}
      className={cn("bg-zinc-50 text-zinc-600 hover:text-zinc-950", className)}
      aria-label={copied ? "Copied to clipboard" : "Copy to clipboard"}
      {...props}
    >
      {copied ? <Check className="h-4 w-4 text-emerald-600" /> : <Copy className="h-4 w-4" />}
    </Button>
  );
}
