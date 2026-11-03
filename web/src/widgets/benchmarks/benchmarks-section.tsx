import { BENCHMARKS } from "../../shared/const/benchmarks";
import { type Language, DICTIONARY } from "../../shared/const/content";
import { MetricCard } from "../../entities/benchmark/metric-card";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";
import { CustomTimerBox } from "../../features/timer-demo/custom-timer-box";

export function BenchmarksSection({ lang }: { lang: Language }) {
  const heading = DICTIONARY[lang].benchmarksHeading;

  return (
    <section id="benchmarks" className="py-20 border-t border-slate-200/80 bg-slate-50/60">
      <Container>
        <SectionHeading
          badge={heading.badge}
          title={heading.title}
          subtitle={heading.subtitle}
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
          {BENCHMARKS.map((metric) => (
            <MetricCard key={metric.label} metric={metric} />
          ))}
        </div>

        {/* Custom sleep timer simulator */}
        <CustomTimerBox />
      </Container>
    </section>
  );
}
