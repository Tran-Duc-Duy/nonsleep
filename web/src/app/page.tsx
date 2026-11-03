"use client";

import * as React from "react";
import { type Language } from "../shared/const/content";
import { Header } from "../widgets/header/header";
import { Hero } from "../widgets/hero/hero";
import { PainRelief } from "../widgets/pain-relief/pain-relief";
import { FeaturesBento } from "../widgets/features-bento/features-bento";
import { TerminalDemo } from "../widgets/terminal-demo/terminal-demo";
import { AgentEcosystem } from "../widgets/agent-ecosystem/agent-ecosystem";
import { ComparisonSection } from "../widgets/comparison/comparison-section";
import { BenchmarksSection } from "../widgets/benchmarks/benchmarks-section";
import { SecurityTrust } from "../widgets/security-trust/security-trust";
import { FaqSection } from "../widgets/faq/faq-section";
import { Footer } from "../widgets/footer/footer";

export default function Home() {
  const [lang, setLang] = React.useState<Language>("en");

  // Keep the document language in step with the switcher: screen readers pick pronunciation
  // from it, and a page serving Vietnamese while declaring `lang="en"` is simply mislabelled.
  React.useEffect(() => {
    document.documentElement.lang = lang;
  }, [lang]);

  return (
    <div className="flex min-h-screen flex-col bg-[#f5f5f7] text-[#1d1d1f] selection:bg-indigo-500/15 selection:text-indigo-900">
      <Header lang={lang} onLanguageChange={setLang} />
      <main className="flex-1">
        <Hero lang={lang} />
        <PainRelief lang={lang} />
        <FeaturesBento lang={lang} />
        <TerminalDemo />
        <AgentEcosystem lang={lang} />
        <ComparisonSection lang={lang} />
        <BenchmarksSection lang={lang} />
        <SecurityTrust lang={lang} />
        <FaqSection lang={lang} />
      </main>
      <Footer />
    </div>
  );
}
