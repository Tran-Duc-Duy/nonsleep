"use client";

import {
  Laptop,
  Bot,
  HeartPulse,
  Lock,
  ShieldCheck,
  Timer,
  type LucideIcon,
  Sparkles,
} from "lucide-react";
import { type Language, DICTIONARY, type FeatureContent } from "../../shared/const/content";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";
import { Card } from "../../shared/ui/card";
import { Badge } from "../../shared/ui/badge";

const ICON_MAP: Record<FeatureContent["iconName"], LucideIcon> = {
  Laptop,
  Bot,
  HeartPulse,
  Lock,
  ShieldCheck,
  Timer,
};

export function FeaturesBento({ lang }: { lang: Language }) {
  const heading = DICTIONARY[lang].featuresHeading;
  const features = DICTIONARY[lang].features;

  return (
    <section id="features" className="py-20 border-t border-black/[0.06] bg-[#f5f5f7]">
      <Container>
        <SectionHeading
          badge={heading.badge}
          title={heading.title}
          subtitle={heading.subtitle}
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature) => {
            const IconComponent = ICON_MAP[feature.iconName];
            return (
              <Card
                key={feature.id}
                className="h-full flex flex-col justify-between group bg-white border-black/[0.07] hover:border-indigo-300 hover:shadow-[0_8px_30px_-6px_rgba(99,102,241,0.12)] transition-all duration-200"
              >
                <div className="flex-1 flex flex-col">
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-indigo-50 border border-indigo-100 text-indigo-600 group-hover:scale-105 transition-all">
                      <IconComponent className="h-5 w-5" />
                    </div>
                    <Badge variant="glow">{feature.badge}</Badge>
                  </div>

                  <h3 className="text-lg font-bold text-[#1d1d1f] mb-1.5 group-hover:text-indigo-600 transition-colors">
                    {feature.title}
                  </h3>
                  <p className="text-xs font-semibold text-indigo-700 mb-3">{feature.tagline}</p>
                  <p className="text-xs text-[#6e6e73] leading-relaxed mb-4">
                    {feature.description}
                  </p>
                </div>

                <div className="pt-3.5 border-t border-zinc-100 text-[11px] text-[#6e6e73] flex items-start gap-1.5 bg-[#fbfbfd] -mx-6 -mb-6 p-4 rounded-b-2xl">
                  <Sparkles className="h-3.5 w-3.5 text-amber-500 shrink-0 mt-0.5" />
                  <span className="leading-snug">{feature.humanNote}</span>
                </div>
              </Card>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
