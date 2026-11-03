"use client";

import { XCircle, CheckCircle2 } from "lucide-react";
import { type Language, DICTIONARY } from "../../shared/const/content";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";
import { Card } from "../../shared/ui/card";

export function PainRelief({ lang }: { lang: Language }) {
  const t = DICTIONARY[lang].painRelief;

  return (
    <section className="py-20 border-t border-black/[0.06] bg-white">
      <Container>
        <SectionHeading badge={t.badge} title={t.title} subtitle={t.subtitle} />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Before */}
          <Card className="h-full flex flex-col justify-start border-rose-200/80 bg-rose-50/30 p-6 sm:p-8 shadow-sm">
            <div className="flex items-center gap-2.5 mb-6 text-rose-700 font-bold text-base sm:text-lg">
              <XCircle className="h-5 w-5 shrink-0 text-rose-600" />
              <span>{t.beforeTitle}</span>
            </div>

            <ul className="space-y-4">
              {t.beforePoints.map((point, i) => (
                <li key={i} className="flex items-start gap-3 text-xs sm:text-sm text-[#52525b]">
                  <span className="flex h-5 w-5 items-center justify-center rounded-full bg-rose-100 text-rose-700 text-xs font-semibold shrink-0 mt-0.5">
                    {i + 1}
                  </span>
                  <span className="leading-relaxed">{point}</span>
                </li>
              ))}
            </ul>
          </Card>
          {/* After */}
          <Card className="h-full flex flex-col justify-start border-emerald-200/80 bg-emerald-50/40 p-6 sm:p-8 shadow-sm">
            <div className="flex items-center gap-2.5 mb-6 text-emerald-800 font-bold text-base sm:text-lg">
              <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-600" />
              <span>{t.afterTitle}</span>
            </div>

            <ul className="space-y-4">
              {t.afterPoints.map((point, i) => (
                <li key={i} className="flex items-start gap-3 text-xs sm:text-sm text-[#1d1d1f]">
                  <span className="flex h-5 w-5 items-center justify-center rounded-full bg-emerald-200/80 text-emerald-800 text-xs font-semibold shrink-0 mt-0.5">
                    ✓
                  </span>
                  <span className="leading-relaxed font-medium">{point}</span>
                </li>
              ))}
            </ul>
          </Card>
        </div>
      </Container>
    </section>
  );
}
