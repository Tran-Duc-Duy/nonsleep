import { Check, X } from "lucide-react";
import { COMPARISON_DATA, type ComparisonRow } from "../../shared/const/comparisons";
import { type Language } from "../../shared/const/content";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";

function renderCell(val: boolean | string) {
  if (val === true) {
    return (
      <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-emerald-100 text-emerald-700 border border-emerald-300">
        <Check className="h-3.5 w-3.5" />
      </span>
    );
  }
  if (val === false) {
    return (
      <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-rose-100 text-rose-700 border border-rose-300">
        <X className="h-3.5 w-3.5" />
      </span>
    );
  }
  return <span className="text-xs text-zinc-700 font-medium">{val}</span>;
}

export function ComparisonSection({ lang }: { lang: Language }) {
  return (
    <section id="comparison" className="py-20 border-t border-zinc-200/80 bg-white">
      <Container>
        <SectionHeading
          badge={lang === "vi" ? "So sánh trực quan" : "Direct Comparison"}
          title={lang === "vi" ? "NonSleep Khác Gì Với Các Tool Khác?" : "How NonSleep Compares"}
          subtitle={
            lang === "vi"
              ? "So sánh khách quan về tính năng, độ an toàn và kiến trúc kỹ thuật giữa NonSleep và các lựa chọn khác."
              : "An objective architectural look across all keep-awake solutions for macOS."
          }
        />

        <div className="overflow-x-auto rounded-2xl border border-zinc-200 bg-white shadow-sm">
          <table className="w-full text-left border-collapse text-xs sm:text-sm">
            <thead>
              <tr className="border-b border-zinc-200 bg-zinc-50/80">
                <th className="py-4 px-4 sm:px-6 font-bold text-zinc-900">Capability</th>
                <th className="py-4 px-4 font-extrabold text-indigo-700 bg-indigo-50/80 border-x border-indigo-200 text-center">
                  NonSleep (Ours)
                </th>
                <th className="py-4 px-4 text-center text-zinc-600 font-medium">Amphetamine</th>
                <th className="py-4 px-4 text-center text-zinc-600 font-medium">Caffeinate</th>
                <th className="py-4 px-4 text-center text-zinc-600 font-medium">Agent Caffeine</th>
                <th className="py-4 px-4 text-center text-zinc-600 font-medium">Amped</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-200/70">
              {COMPARISON_DATA.map((row: ComparisonRow, idx) => (
                <tr key={idx} className="hover:bg-zinc-50/60 transition-colors">
                  <td className="py-3.5 px-4 sm:px-6 font-medium text-zinc-900">
                    <div>{row.capability}</div>
                    <div className="text-[11px] text-zinc-500 mt-0.5">{row.note}</div>
                  </td>
                  <td className="py-3.5 px-4 text-center bg-indigo-50/30 border-x border-indigo-100 font-bold">
                    {renderCell(row.nonSleep)}
                  </td>
                  <td className="py-3.5 px-4 text-center">{renderCell(row.amphetamine)}</td>
                  <td className="py-3.5 px-4 text-center">{renderCell(row.caffeinate)}</td>
                  <td className="py-3.5 px-4 text-center">{renderCell(row.agentCaffeine)}</td>
                  <td className="py-3.5 px-4 text-center">{renderCell(row.amped)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Container>
    </section>
  );
}
