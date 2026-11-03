import { Bot, Terminal, Zap } from "lucide-react";
import { AgentItem } from "../../shared/const/agents";
import { Badge } from "../../shared/ui/badge";
import { Card } from "../../shared/ui/card";

export function AgentCard({ agent }: { agent: AgentItem }) {
  return (
    <Card className="h-full flex flex-col justify-between border-zinc-200/90 bg-white hover:border-indigo-300 hover:shadow-md transition-all duration-200">
      <div className="flex-1 flex flex-col">
        <div className="flex items-center justify-between gap-2 mb-3">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-50 border border-indigo-200 text-indigo-600">
              <Bot className="h-5 w-5" />
            </div>
            <div>
              <h3 className="font-bold text-zinc-900">{agent.name}</h3>
              <p className="text-xs text-zinc-500">{agent.tag}</p>
            </div>
          </div>
          <Badge variant={agent.mechanism === "Official Hook" ? "glow" : "success"}>
            {agent.mechanism}
          </Badge>
        </div>

        <p className="text-xs text-zinc-600 mb-4 leading-relaxed">{agent.description}</p>

        <div className="mb-4">
          <p className="text-[11px] font-semibold text-zinc-600 uppercase tracking-wider mb-1.5">
            Monitored Events
          </p>
          <div className="flex flex-wrap gap-1.5">
            {agent.events.map((evt) => (
              <span
                key={evt}
                className="inline-flex items-center gap-1 rounded-md bg-zinc-100 px-2 py-0.5 text-[11px] font-mono text-zinc-700 border border-zinc-200/80"
              >
                <Zap className="h-2.5 w-2.5 text-amber-500" />
                {evt}
              </span>
            ))}
          </div>
        </div>
      </div>

      <div className="pt-3 border-t border-zinc-100 flex items-center justify-between text-xs font-mono text-zinc-500">
        <span className="truncate flex items-center gap-1.5 text-zinc-600">
          <Terminal className="h-3.5 w-3.5 shrink-0 text-zinc-400" />
          {agent.installCommand}
        </span>
      </div>
    </Card>
  );
}
