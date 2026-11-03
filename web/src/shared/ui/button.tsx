"use client";

import * as React from "react";
import { cn } from "../lib/utils";

export type ButtonVariant =
  | "primary"
  | "secondary"
  | "outline"
  | "ghost"
  | "glass"
  /** Pill inside a segmented control (language switcher, step picker). Pair with `selected`. */
  | "segmented"
  /** Bordered pill that toggles (command tabs, timer presets). Pair with `selected`. */
  | "chip"
  /** Full-width unstyled row, for disclosure headers. Keeps the element a real button. */
  | "row";

export type ButtonSize = "icon" | "xs" | "sm" | "md" | "lg";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  /** Toggle state for `segmented` and `chip`; also sets `aria-pressed`. */
  selected?: boolean;
}

/**
 * The only button in the app.
 *
 * Call sites used to hand-roll `<button className="…">`, which is how eleven controls drifted
 * below the 44px touch minimum: a rule written per call site is a rule nobody can enforce.
 * Sizing — including that minimum — lives here, once.
 */
export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = "primary", size = "md", selected, children, ...props }, ref) => {
    const base =
      "inline-flex items-center justify-center font-medium rounded-xl transition-all duration-150 cursor-pointer select-none focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50";

    const variants: Record<ButtonVariant, string> = {
      primary: "bg-zinc-950 text-white hover:bg-zinc-800 shadow-sm hover:shadow active:scale-[0.98]",
      secondary:
        "bg-zinc-100 text-zinc-900 hover:bg-zinc-200/80 border border-zinc-200 active:scale-[0.98]",
      outline:
        "border border-zinc-300/80 bg-white text-zinc-800 hover:bg-zinc-50 hover:border-zinc-400 shadow-sm active:scale-[0.98]",
      ghost: "text-zinc-600 hover:text-zinc-950 hover:bg-zinc-100/80",
      glass:
        "bg-white/80 backdrop-blur-md border border-zinc-200 text-zinc-900 hover:bg-white shadow-sm active:scale-[0.98]",
      segmented: selected
        ? "rounded-full bg-white text-[#1d1d1f] shadow-sm font-bold border border-black/[0.06]"
        : "rounded-full text-[#6e6e73] hover:text-[#1d1d1f] hover:bg-white/60 font-medium",
      chip: selected
        ? "border border-indigo-600 bg-indigo-600 text-white shadow-sm font-semibold"
        : "border border-zinc-200 bg-white text-zinc-600 hover:border-zinc-300 hover:text-zinc-900",
      row: "w-full justify-between rounded-none text-left",
    };

    // `min-h` is the WCAG 2.5.5 / Apple HIG touch minimum, applied only to coarse pointers so
    // the mouse layout is untouched. Every control inherits it by construction.
    const touch = "[@media(pointer:coarse)]:min-h-11";

    const sizes: Record<ButtonSize, string> = {
      icon: cn("h-8 w-8 shrink-0 rounded-lg p-0", touch, "[@media(pointer:coarse)]:min-w-11"),
      xs: cn("h-7 px-2.5 text-xs gap-1.5", touch),
      sm: cn("h-8 px-3 text-xs gap-1.5", touch),
      md: cn("h-10 px-4 text-sm gap-2", touch),
      lg: cn("h-12 px-6 text-base gap-2.5", touch),
    };

    const isToggle = variant === "segmented" || variant === "chip";

    return (
      <button
        ref={ref}
        aria-pressed={isToggle ? selected : undefined}
        className={cn(base, variants[variant], sizes[size], className)}
        {...props}
      >
        {children}
      </button>
    );
  }
);

Button.displayName = "Button";
