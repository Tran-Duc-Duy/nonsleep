import Link from "next/link";
import Image from "next/image";
import { Heart } from "lucide-react";
import { GithubIcon } from "../../shared/ui/icons";
import { SITE_CONFIG } from "../../shared/const/site-config";
import { Container } from "../../shared/ui/container";

export function Footer() {
  return (
    <footer className="border-t border-zinc-200 bg-white py-12 text-zinc-500 text-xs">
      <Container className="flex flex-col md:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-2.5">
          <Image
            src="/AppIcon.png"
            alt="NonSleep app icon"
            width={24}
            height={24}
            className="h-6 w-6 rounded-md shadow-sm border border-zinc-200"
          />
          <span className="font-bold text-zinc-900">{SITE_CONFIG.name}</span>
          <span>· Released under {SITE_CONFIG.license} License</span>
        </div>

        <div className="flex items-center gap-6">
          <a
            href={SITE_CONFIG.githubUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-zinc-900 transition-colors flex items-center gap-1.5"
          >
            <GithubIcon className="h-3.5 w-3.5" />
            GitHub
          </a>
          <a
            href={SITE_CONFIG.releasesUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-zinc-900 transition-colors"
          >
            Releases ({SITE_CONFIG.latestVersion})
          </a>
          <a
            href={`${SITE_CONFIG.githubUrl}/blob/main/SECURITY.md`}
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-zinc-900 transition-colors"
          >
            Security Policy
          </a>
          <Link href="/llms.txt" className="hover:text-zinc-900 transition-colors">
            llms.txt (AI Agent Context)
          </Link>
        </div>

        <div className="flex items-center gap-1 text-zinc-500">
          Built with <Heart className="h-3 w-3 text-rose-500 fill-current" /> by{" "}
          <a
            href="https://github.com/Tran-Duc-Duy"
            target="_blank"
            rel="noopener noreferrer"
            className="text-zinc-900 hover:underline font-semibold"
          >
            {SITE_CONFIG.author}
          </a>
        </div>
      </Container>
    </footer>
  );
}
