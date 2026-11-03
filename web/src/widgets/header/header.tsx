"use client";

import Link from "next/link";
import Image from "next/image";
import { Download, Globe } from "lucide-react";
import { GithubIcon } from "../../shared/ui/icons";
import { SITE_CONFIG } from "../../shared/const/site-config";
import { type Language, DICTIONARY } from "../../shared/const/content";
import { Button } from "../../shared/ui/button";
import { Container } from "../../shared/ui/container";

export interface HeaderProps {
  lang: Language;
  onLanguageChange: (lang: Language) => void;
}

export function Header({ lang, onLanguageChange }: HeaderProps) {
  const nav = DICTIONARY[lang].nav;

  return (
    <header className="sticky top-0 z-50 w-full border-b border-black/[0.06] bg-white/80 backdrop-blur-xl transition-all shadow-[0_1px_3px_rgba(0,0,0,0.02)]">
      <Container className="flex h-14 sm:h-16 items-center justify-between gap-2">
        <Link href="/" data-tap-target className="flex shrink-0 items-center gap-2 group">
          {/* next/image, not <img>: the source is a 1024×1024 786 KB PNG rendered at 32 px.
             Decoding it in full delayed the hero's largest paint by ~1 s. */}
          <Image
            src="/AppIcon.png"
            alt="NonSleep app icon"
            width={32}
            height={32}
            priority
            className="h-7 w-7 sm:h-8 sm:w-8 shrink-0 rounded-[9px] shadow-sm border border-black/5 transition-transform group-hover:scale-105"
          />
          <span className="text-base sm:text-lg font-black tracking-tight text-[#1d1d1f]">
            {SITE_CONFIG.name}
          </span>
          <span className="hidden md:inline rounded-full bg-indigo-50 border border-indigo-200/80 px-2 py-0.5 text-[11px] font-mono font-bold text-indigo-700">
            {SITE_CONFIG.latestVersion}
          </span>
        </Link>

        <nav className="hidden lg:flex items-center gap-6 text-sm font-medium text-[#6e6e73]">
          <Link href="#features" className="transition hover:text-[#1d1d1f]">
            {nav.features}
          </Link>
          <Link href="#simulator" className="transition hover:text-[#1d1d1f]">
            {nav.howItWorks}
          </Link>
          <Link href="#agents" className="transition hover:text-[#1d1d1f]">
            {nav.agents}
          </Link>
          <Link href="#comparison" className="transition hover:text-[#1d1d1f]">
            {nav.compare}
          </Link>
          <Link href="#benchmarks" className="transition hover:text-[#1d1d1f]">
            {nav.benchmarks}
          </Link>
          <Link href="#faq" className="transition hover:text-[#1d1d1f]">
            {nav.faq}
          </Link>
        </nav>

        <div className="flex min-w-0 shrink items-center gap-1.5 sm:gap-3">
          <div
            role="group"
            aria-label="Language"
            className="flex shrink-0 items-center rounded-full border border-black/[0.08] bg-[#f5f5f7] p-0.5 text-xs font-semibold shadow-inner"
          >
            <Globe className="hidden md:block h-3.5 w-3.5 text-[#6e6e73] ml-1.5 mr-0.5" aria-hidden="true" />
            {(["en", "vi"] as const).map((code) => (
              <Button
                key={code}
                variant="segmented"
                size="xs"
                selected={lang === code}
                onClick={() => onLanguageChange(code)}
                className="px-2.5 [@media(pointer:coarse)]:min-w-10"
              >
                {code.toUpperCase()}
              </Button>
            ))}
          </div>

          <a
            href={SITE_CONFIG.githubUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:inline-flex"
          >
            <Button variant="outline" size="sm">
              <GithubIcon className="h-4 w-4" />
              GitHub
            </Button>
          </a>
          <a href={SITE_CONFIG.downloadMacUrl} className="shrink-0">
            {/* Label hidden on phones: with it, the header needed 391px on a 320px screen and
                the brand name was truncated to fit. The icon plus aria-label carries it. */}
            <Button variant="primary" size="sm" aria-label={nav.download}>
              <Download className="h-4 w-4" />
              <span className="hidden sm:inline">{nav.download}</span>
            </Button>
          </a>
        </div>
      </Container>
    </header>
  );
}
