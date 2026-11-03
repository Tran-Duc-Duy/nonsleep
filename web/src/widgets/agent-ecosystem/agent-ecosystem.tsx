import { AGENTS } from "../../shared/const/agents";
import { type Language } from "../../shared/const/content";
import { AgentCard } from "../../entities/agent/agent-card";
import { Container } from "../../shared/ui/container";
import { SectionHeading } from "../../shared/ui/section-heading";
import { AgentPromptBox } from "../../features/agent-prompt/agent-prompt-box";

export function AgentEcosystem({ lang }: { lang: Language }) {
  return (
    <section id="agents" className="py-20 border-t border-zinc-200/80 bg-zinc-50/50">
      <Container>
        <SectionHeading
          badge={lang === "vi" ? "Hệ sinh thái Agent" : "Agent Ecosystem"}
          title={lang === "vi" ? "Hỗ Trợ Mọi Coding Agent Hàng Đầu" : "Native Hooks for Every Major Agent"}
          subtitle={
            lang === "vi"
              ? "Dù bạn dùng Claude Code, Cursor, Codex, hay omp, NonSleep đều kết nối vào vòng đời turn tự động."
              : "Whether you code with Claude Code, Cursor, Codex, or omp, NonSleep attaches to the turn lifecycle seamlessly."
          }
        />

        {/* 1-Click Agent Auto-Install Prompt Box */}
        <div className="mb-12">
          <AgentPromptBox lang={lang} />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {AGENTS.map((agent) => (
            <AgentCard key={agent.id} agent={agent} />
          ))}
        </div>
      </Container>
    </section>
  );
}
