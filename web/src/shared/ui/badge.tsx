import * as React from "react";
import { cn } from "../lib/utils";

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: "default" | "success" | "outline" | "glow";
}

export function Badge({ className, variant = "default", children, ...props }: BadgeProps) {
  const variants = {
    default: "bg-zinc-100 text-zinc-700 border border-zinc-200/80",
    success: "bg-emerald-50 text-emerald-700 border border-emerald-200",
    outline: "border border-zinc-300 text-zinc-600 bg-white",
    glow: "bg-indigo-50 text-indigo-700 border border-indigo-200 shadow-sm",
  };

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium tracking-wide",
        variants[variant],
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
}
