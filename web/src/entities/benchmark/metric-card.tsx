import { BenchmarkMetric } from "../../shared/const/benchmarks";
import { Card } from "../../shared/ui/card";

export function MetricCard({ metric }: { metric: BenchmarkMetric }) {
  return (
    <Card className="h-full flex flex-col justify-between border-zinc-200/90 bg-white hover:border-zinc-300 hover:shadow-md transition-all duration-200">
      <div className="flex-1 flex flex-col">
        <div className="flex items-center justify-between mb-2">
          <span className="text-xs font-semibold uppercase tracking-wider text-zinc-500">
            {metric.label}
          </span>
          <span className="rounded-full bg-emerald-50 border border-emerald-200 px-2 py-0.5 text-[11px] font-semibold text-emerald-700">
            {metric.highlight}
          </span>
        </div>
        <div className="text-3xl font-extrabold tracking-tight text-zinc-950 mb-2">
          {metric.value}
        </div>
        <p className="text-xs text-zinc-600 leading-relaxed mb-4">{metric.description}</p>
      </div>

      <div className="pt-3 border-t border-zinc-100 text-[11px] text-zinc-500 flex items-center gap-1.5 mt-auto">
        <span className="text-indigo-600 font-bold">vs</span>
        <span>{metric.comparison}</span>
      </div>
    </Card>
  );
}
