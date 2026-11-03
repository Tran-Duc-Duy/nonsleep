import * as React from "react";
import { Badge } from "./badge";
import { cn } from "../lib/utils";

export interface SectionHeadingProps {
  badge?: string;
  title: string;
  subtitle?: string;
  align?: "center" | "left";
  className?: string;
}

export function SectionHeading({
  badge,
  title,
  subtitle,
  align = "center",
  className,
}: SectionHeadingProps) {
  return (
    <div
      className={cn(
        "flex flex-col space-y-3 mb-12",
        align === "center" ? "items-center text-center" : "items-start text-left",
        className
      )}
    >
      {badge && <Badge variant="glow">{badge}</Badge>}
      <h2 className="text-3xl font-extrabold tracking-tight text-[#1d1d1f] sm:text-4xl">{title}</h2>
      {subtitle && <p className="max-w-2xl text-base text-[#6e6e73] sm:text-lg leading-relaxed">{subtitle}</p>}
    </div>
  );
}
