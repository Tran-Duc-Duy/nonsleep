export interface AgentItem {
  id: string;
  name: string;
  tag: string;
  configPath: string;
  mechanism: "Official Hook" | "Power Assertion";
  description: string;
  events: string[];
  installCommand: string;
}

export const AGENTS: readonly AgentItem[] = [
  {
    id: "claude-code",
    name: "Claude Code",
    tag: "Anthropic CLI",
    configPath: "~/.claude/settings.json",
    mechanism: "Official Hook",
    description:
      "Holds lease during UserPromptSubmit and PostToolUse; releases on Stop or Notification.",
    events: ["UserPromptSubmit", "PostToolUse", "Stop", "SessionEnd"],
    installCommand: "nonsleep integrate claude",
  },
  {
    id: "cursor",
    name: "Cursor",
    tag: "AI IDE",
    configPath: "~/.cursor/hooks.json",
    mechanism: "Official Hook",
    description:
      "Listens to observe-only events (beforeSubmitPrompt, postToolUse, stop, sessionEnd).",
    events: ["beforeSubmitPrompt", "postToolUse", "afterShellExecution", "stop"],
    installCommand: "nonsleep integrate cursor",
  },
  {
    id: "codex",
    name: "OpenAI Codex",
    tag: "OpenAI CLI",
    configPath: "~/.codex/hooks.json",
    mechanism: "Official Hook",
    description:
      "Captures prompt start, tool usage, and stop lifecycle to manage MacBook sleep seamlessly.",
    events: ["UserPromptSubmit", "PreToolUse", "PostToolUse", "Stop", "SubagentStop"],
    installCommand: "nonsleep integrate codex",
  },
  {
    id: "omp",
    name: "omp (oh-my-pi)",
    tag: "Agent Harness",
    configPath: "Built-in (Zero config)",
    mechanism: "Power Assertion",
    description:
      "NonSleep automatically reads omp's 'omp agent session' power assertion via IOKit.",
    events: ["Auto-detected turn in flight across all providers"],
    installCommand: "Built in — no setup needed",
  },
  {
    id: "antigravity",
    name: "Antigravity",
    tag: "Google Agent",
    configPath: "~/.gemini/config/hooks.json",
    mechanism: "Official Hook",
    description:
      "Supports CLI, App, and IDE. Observes PreInvocation, PostToolUse, and fullyIdle Stop state.",
    events: ["PreInvocation", "PostToolUse", "Stop"],
    installCommand: "nonsleep integrate antigravity",
  },
] as const;
