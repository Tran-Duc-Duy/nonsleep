import { ShieldCheck, WifiOff, FileCheck, Lock, Terminal } from "lucide-react";
import { type Language, DICTIONARY } from "../../shared/const/content";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";
import { Card } from "../../shared/ui/card";

export function SecurityTrust({ lang }: { lang: Language }) {
  const heading = DICTIONARY[lang].securityHeading;

  const securityPillars = [
    {
      title: lang === "vi" ? "100% Offline (Không Kết Nối Mạng)" : "100% Offline (Air-Gapped)",
      description:
        lang === "vi"
          ? "Code không import URLSession hay bất kỳ socket mạng nào. Không thu thập telemetry, tracking, hay crash logs. Bạn có thể tự gõ `lsof -p $(pgrep NonSleepBar) -i` (kết quả trả về trống rỗng)."
          : "Zero network imports (URLSession, Network, sockets). Zero telemetry, tracking, or crash analytics. Verify yourself via `lsof -p $(pgrep NonSleepBar) -i` (returns empty).",
      icon: WifiOff,
    },
    {
      title: lang === "vi" ? "Không Dùng Thư Viện Ngoài" : "Zero Third-Party Dependencies",
      description:
        lang === "vi"
          ? "Chỉ liên kết trực tiếp với Swift Standard Library và hệ thống Apple SDK (AppKit, SwiftUI, IOKit). Triệt tiêu 100% nguy cơ tấn công chuỗi cung ứng (supply-chain attack)."
          : "Links exclusively against the Swift standard library and Apple system frameworks (AppKit, SwiftUI, IOKit). Eliminates supply-chain poisoning risks completely.",
      icon: ShieldCheck,
    },
    {
      title: lang === "vi" ? "Vá Lỗ Hổng TOCTOU Khi Cài Sudoers" : "TOCTOU-Proof Sudoers Setup",
      description:
        lang === "vi"
          ? "File nháp được copy vào /etc/sudoers.d/ với quyền 0440 root:wheel trước khi visudo -c kiểm tra, ngăn chặn tuyệt đối tiến trình user tráo file giữa lúc check và lúc cài."
          : "Draft rules are staged directly into /etc/sudoers.d/ as 0440 root:wheel before visudo -c verification, preventing local processes from swapping files mid-check.",
      icon: Lock,
    },
    {
      title: lang === "vi" ? "Chữ Ký Xuất Xứ Build SLSA Level 3" : "Cryptographic SLSA Build Provenance",
      description:
        lang === "vi"
          ? "Mọi bản build release được biên dịch công khai trên GitHub Actions với commit SHA cố định và được GitHub Artifact Attestations ký số độc lập."
          : "All release binaries are compiled on public GitHub Actions with pinned commit SHAs and signed with GitHub Artifact Attestations (SLSA Level 3).",
      icon: FileCheck,
    },
  ];

  return (
    <section id="security" className="py-20 border-t border-zinc-200/80 bg-white">
      <Container>
        <SectionHeading
          badge={heading.badge}
          title={heading.title}
          subtitle={heading.subtitle}
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          {securityPillars.map((pillar) => {
            const Icon = pillar.icon;
            return (
              <Card key={pillar.title} className="h-full flex flex-col justify-start p-6 bg-white border-zinc-200 shadow-sm">
                <div className="flex items-center gap-3 mb-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-600">
                    <Icon className="h-5 w-5" />
                  </div>
                  <h3 className="font-bold text-zinc-900 text-base">{pillar.title}</h3>
                </div>
                <p className="text-xs sm:text-sm text-zinc-600 leading-relaxed font-normal">
                  {pillar.description}
                </p>
              </Card>
            );
          })}
        </div>

        {/* Verification Command Callout */}
        <div className="rounded-2xl border border-zinc-200 bg-zinc-50 p-6 font-mono text-xs text-zinc-800 shadow-sm">
          <div className="flex items-center gap-2 text-indigo-700 font-bold mb-2">
            <Terminal className="h-4 w-4" />
            <span>
              {lang === "vi"
                ? "Lệnh Tự Kiểm Chứng Chữ Ký Nguồn Gốc Bản Build Tại Máy:"
                : "Verify Release Provenance Locally:"}
            </span>
          </div>
          <div className="rounded-xl bg-white border border-zinc-200 px-3.5 py-2.5 text-zinc-700 overflow-x-auto shadow-inner">
            <code>gh attestation verify NonSleep-0.2.0-macOS.zip --owner Tran-Duc-Duy</code>
          </div>
        </div>
      </Container>
    </section>
  );
}
