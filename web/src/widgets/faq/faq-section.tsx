"use client";

import * as React from "react";
import { ChevronDown, HelpCircle } from "lucide-react";
import { type Language, DICTIONARY } from "../../shared/const/content";
import { FAQS, type FaqItem } from "../../shared/const/faq";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";
import { Button } from "../../shared/ui/button";

export function FaqSection({ lang }: { lang: Language }) {
  const heading = DICTIONARY[lang].faqHeading;
  const [openIds, setOpenIds] = React.useState<Record<string, boolean>>({
    "how-clamshell-works": true,
  });

  const toggle = (id: string) => {
    setOpenIds((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  return (
    <section id="faq" className="py-14 sm:py-20 border-t border-zinc-200/80 bg-zinc-50/60">
      <Container>
        <SectionHeading
          badge={heading.badge}
          title={heading.title}
          subtitle={heading.subtitle}
        />

        <div className="mx-auto max-w-3xl space-y-2.5 sm:space-y-4">
          {FAQS.map((faq: FaqItem) => {
            const isOpen = Boolean(openIds[faq.id]);
            return (
              <div
                key={faq.id}
                className="rounded-2xl border border-zinc-200/90 bg-white shadow-sm transition-all duration-200 overflow-hidden"
              >
                <Button
                  variant="row"
                  size="md"
                  onClick={() => toggle(faq.id)}
                  className="h-auto gap-3 px-4 py-3.5 sm:px-5 sm:py-4 font-bold text-zinc-900 text-sm sm:text-base hover:text-indigo-600 hover:bg-transparent"
                  aria-expanded={isOpen}
                >
                  <span className="flex items-center gap-3">
                    <HelpCircle className="h-4 w-4 text-indigo-600 shrink-0" />
                    {faq.question}
                  </span>
                  <ChevronDown
                    className={`h-4 w-4 text-zinc-400 transition-transform duration-200 shrink-0 ${
                      isOpen ? "rotate-180 text-indigo-600" : ""
                    }`}
                  />
                </Button>

                {isOpen && (
                  <div className="px-4 sm:px-5 pb-4 sm:pb-5 pt-1 text-xs sm:text-sm text-zinc-600 leading-relaxed border-t border-zinc-100">
                    {faq.answer}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
