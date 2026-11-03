import { ImageResponse } from "next/og";
import { SITE_CONFIG } from "../shared/const/site-config";

// `next/og` ships with Next.js, so the share card costs no extra dependency.
export const runtime = "nodejs";
export const alt = SITE_CONFIG.title;
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          background: "linear-gradient(135deg, #0b1020 0%, #1b1740 55%, #311b52 100%)",
          padding: "72px 80px",
          fontFamily: "sans-serif",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 20 }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              width: 68,
              height: 68,
              borderRadius: 20,
              background: "rgba(255,255,255,0.1)",
              border: "1px solid rgba(255,255,255,0.22)",
              fontSize: 36,
            }}
          >
            ☾
          </div>
          <div style={{ display: "flex", flexDirection: "column" }}>
            <div style={{ fontSize: 38, fontWeight: 700, color: "#ffffff" }}>NonSleep</div>
            <div style={{ fontSize: 22, color: "#a5b4fc" }}>{`${SITE_CONFIG.latestVersion} · MIT`}</div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 20 }}>
          <div
            style={{
              fontSize: 64,
              fontWeight: 800,
              color: "#ffffff",
              lineHeight: 1.12,
              letterSpacing: -1.5,
            }}
          >
            Keep your Mac working with the lid closed
          </div>
          <div style={{ fontSize: 30, color: "#c7d2fe", lineHeight: 1.35 }}>
            For AI coding agents — Claude Code, Cursor, Codex, omp. Sleeps the moment they finish.
          </div>
        </div>

        <div style={{ display: "flex", gap: 14 }}>
          {["No external display", "100% offline", "Zero dependencies", "macOS + Linux"].map((tag) => (
            <div
              key={tag}
              style={{
                display: "flex",
                fontSize: 23,
                color: "#e0e7ff",
                background: "rgba(255,255,255,0.08)",
                border: "1px solid rgba(255,255,255,0.18)",
                borderRadius: 999,
                padding: "11px 24px",
              }}
            >
              {tag}
            </div>
          ))}
        </div>
      </div>
    ),
    size
  );
}
