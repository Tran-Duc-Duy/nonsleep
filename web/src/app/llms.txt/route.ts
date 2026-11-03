import { NextResponse } from "next/server";
import fs from "node:fs";
import path from "node:path";

// Statically generated at build time. Reading the repo-root file with `fs` at request time
// worked locally only: a deployed bundle has neither the parent directory nor the same cwd,
// so the route would 500 in production. Resolving at build time keeps the repo root as the
// single source of truth while shipping the content inside the build output.
export const dynamic = "force-static";

const FALLBACK = `# NonSleep

> NonSleep keeps a MacBook working with the lid closed and no external display while AI coding agents or long tasks run, then lets it sleep again the moment they finish.

## Docs

- [README](https://github.com/Tran-Duc-Duy/nonsleep/blob/main/README.md): install, CLI reference, configuration.
`;

function readLlmsTxt(): string {
  for (const candidate of [
    path.resolve(process.cwd(), "llms.txt"),
    path.resolve(process.cwd(), "..", "llms.txt"),
  ]) {
    try {
      if (fs.existsSync(candidate)) return fs.readFileSync(candidate, "utf-8");
    } catch {
      // Try the next candidate; a missing file must never fail the build.
    }
  }
  return FALLBACK;
}

const CONTENT = readLlmsTxt();

export function GET() {
  return new NextResponse(CONTENT, {
    headers: {
      "Content-Type": "text/plain; charset=utf-8",
      "Cache-Control": "public, max-age=86400",
    },
  });
}
