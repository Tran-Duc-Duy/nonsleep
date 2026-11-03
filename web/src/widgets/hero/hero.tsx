"use client";

import {
    Download,
    ShieldCheck,
    Cpu,
    WifiOff,
    Lock,
    Sparkles,
} from "lucide-react";
import { GithubIcon } from "../../shared/ui/icons";
import Image from "next/image";
import { SITE_CONFIG } from "../../shared/const/site-config";
import { type Language, DICTIONARY } from "../../shared/const/content";
import { Button } from "../../shared/ui/button";
import { Container } from "../../shared/ui/container";
import { LottiePlayer } from "../../shared/ui/lottie-player";
import pulseGlow from "../../shared/assets/lottie/pulse-glow.json";
import { InstallSnippet } from "../../features/copy-command/install-snippet";
import { MacbookMockup } from "../../features/macbook-mockup/macbook-mockup";

export function Hero({ lang }: { lang: Language }) {
    const t = DICTIONARY[lang].hero;

    return (
        <section className="relative overflow-hidden pt-12 pb-20 md:pt-16 md:pb-28 bg-[#f5f5f7]">
            {/* Soft ambient background glow */}
            <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[350px] bg-gradient-to-tr from-indigo-100/40 via-violet-100/25 to-transparent blur-[140px] pointer-events-none rounded-full" />

            <Container className="relative flex flex-col items-center text-center">
                {/* Release Pill (Zero right arrows) */}
                <a
                    href={SITE_CONFIG.releasesUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    data-tap-target
                    className="inline-flex items-center gap-2 rounded-full border border-indigo-200/80 bg-white/90 px-4 py-1.5 text-xs font-semibold text-indigo-700 shadow-sm transition-all hover:bg-indigo-50/60 mb-6"
                >
                    <span>{t.pill}</span>
                </a>

                {/* Luxury Apple Hardware Icon Stage */}
                <div className="relative mb-6 flex items-center justify-center">
                    <div className="absolute -inset-6 w-36 h-36 pointer-events-none opacity-40">
                        <LottiePlayer
                            animationData={pulseGlow}
                            className="w-full h-full"
                        />
                    </div>
                    <div className="relative rounded-[22px] p-1 bg-gradient-to-b from-white to-zinc-200/80 shadow-[0_12px_32px_-6px_rgba(0,0,0,0.12)] border border-black/5">
                        <Image
                            src="/AppIcon.png"
                            alt="NonSleep app icon"
                            width={80}
                            height={80}
                            priority
                            className="h-20 w-20 rounded-[18px] transition-transform hover:scale-105 duration-200"
                        />
                    </div>
                </div>

                {/* Headline with Clean, Explicit Line-Breaks (Never Awkwardly Breaks) */}
                <h1 className="max-w-5xl mx-auto text-4xl sm:text-6xl lg:text-7xl font-black tracking-tight text-[#1d1d1f] leading-[1.12]">
                    <span className="block sm:whitespace-nowrap">
                        {t.titleLine1}
                    </span>
                    <span className="block mt-1 bg-gradient-to-r from-indigo-600 via-violet-600 to-indigo-500 bg-clip-text text-transparent">
                        {t.titleLine2}
                    </span>
                </h1>

                {/* Subtitle */}
                <p className="mt-5 max-w-2xl text-base sm:text-lg lg:text-xl text-[#6e6e73] leading-relaxed font-normal">
                    {t.subtitle}
                </p>

                {/* Actions */}
                <div className="mt-9 flex flex-col sm:flex-row items-center gap-3.5 w-full sm:w-auto">
                    <a
                        href={SITE_CONFIG.downloadMacUrl}
                        className="w-full sm:w-auto"
                    >
                        <Button
                            variant="primary"
                            size="lg"
                            className="w-full sm:w-auto text-base"
                        >
                            <Download className="h-5 w-5 mr-1" />
                            {t.downloadCta}
                        </Button>
                    </a>
                    <a
                        href={SITE_CONFIG.githubUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="w-full sm:w-auto"
                    >
                        <Button
                            variant="outline"
                            size="lg"
                            className="w-full sm:w-auto text-base"
                        >
                            <GithubIcon className="h-5 w-5 mr-1" />
                            {t.githubCta}
                        </Button>
                    </a>
                </div>

                <p className="mt-2.5 text-xs text-[#6e6e73] font-medium">
                    {t.downloadSub}
                </p>

                {/* CLI 1-liner snippet */}
                <div className="mt-6 w-full max-w-xl">
                    <InstallSnippet command={SITE_CONFIG.installCommand} />
                </div>

                {/* Clean Light-Mode Simulator */}
                <div id="simulator" className="mt-14 w-full">
                    <MacbookMockup lang={lang} />
                </div>

                {/* Value Highlights */}
                <div className="mt-14 grid grid-cols-2 sm:grid-cols-4 gap-6 pt-8 border-t border-black/[0.08] text-xs sm:text-sm text-[#6e6e73] w-full">
                    <div className="flex items-center justify-center gap-2">
                        <WifiOff className="h-4 w-4 text-emerald-600" />
                        <span className="font-semibold text-[#1d1d1f]">
                            {t.badgeOffline}
                        </span>
                    </div>
                    <div className="flex items-center justify-center gap-2">
                        <Cpu className="h-4 w-4 text-indigo-600" />
                        <span className="font-semibold text-[#1d1d1f]">
                            {t.badgeNative}
                        </span>
                    </div>
                    <div className="flex items-center justify-center gap-2">
                        <ShieldCheck className="h-4 w-4 text-amber-600" />
                        <span className="font-semibold text-[#1d1d1f]">
                            {t.badgeSafe}
                        </span>
                    </div>
                    <div className="flex items-center justify-center gap-2">
                        <Lock className="h-4 w-4 text-sky-600" />
                        <span className="font-semibold text-[#1d1d1f]">
                            {t.badgeLock}
                        </span>
                    </div>
                </div>
            </Container>
        </section>
    );
}
