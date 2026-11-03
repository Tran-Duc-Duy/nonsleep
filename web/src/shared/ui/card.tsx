import * as React from "react";
import { cn } from "../lib/utils";

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  glow?: boolean;
}

export function Card({ className, glow = false, ...props }: CardProps) {
  return (
    <div
      className={cn(
        "relative rounded-2xl bg-white p-6 sm:p-7 transition-all duration-200",
        "border border-black/[0.07]",
        "shadow-[0_1px_2px_rgba(0,0,0,0.02),0_4px_16px_-2px_rgba(0,0,0,0.03),0_12px_32px_-4px_rgba(0,0,0,0.04)]",
        "hover:shadow-[0_6px_20px_rgba(0,0,0,0.04),0_16px_40px_-6px_rgba(0,0,0,0.06)]",
        "hover:border-black/[0.12] hover:-translate-y-0.5",
        glow && "border-indigo-500/20 bg-gradient-to-br from-indigo-50/30 via-white to-white shadow-[0_8px_30px_-6px_rgba(99,102,241,0.08)]",
        className
      )}
      {...props}
    />
  );
}

export function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("flex flex-col space-y-1.5", className)} {...props} />;
}

export function CardTitle({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className={cn("text-lg font-bold tracking-tight text-[#1d1d1f]", className)}
      {...props}
    />
  );
}

export function CardDescription({ className, ...props }: React.HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p
      className={cn("text-sm text-[#6e6e73] leading-relaxed font-normal", className)}
      {...props}
    />
  );
}

export function CardContent({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("pt-4", className)} {...props} />;
}
