# 04. Động cơ nội dung & Bài viết chuyên sâu (Content & Copywriting Engine)

Tài liệu này bao gồm các bài viết kỹ thuật hoàn chỉnh (sẵn sàng đăng trên Dev.to, Medium, Hashnode), kịch bản video viral và chuỗi tweet (Twitter Thread) cho X.

---

## 1. Bài viết kỹ thuật dài (Engineering Deep Dive Blog Post)
*Đăng trên:* Dev.to, Hashnode, hoặc Medium (Mục *Software Engineering / macOS*).

### Tiêu đề:
> **Why macOS Ignores Caffeinate When You Close Your Laptop Lid (And How We Fixed It With Distributed Leases)**

### Nội dung:
```markdown
If you are a developer using AI coding agents like Claude Code, Cursor, or running long Docker builds and local LLM models on Apple Silicon, you have almost certainly encountered this frustration:

You trigger a 15-minute background task, close your MacBook lid to catch your train or head home, and arrive only to find out that your task was instantly suspended the millisecond the clamshell shut.

"Wait," you say, "why didn't `caffeinate` keep it awake?"

Here is the low-level operating system reality of how macOS manages power, why standard sleep-prevention tools fail, and how we solved it in pure Swift without running insecure root daemons.

---

### The Architecture of Clamshell Sleep in IOKit

Standard macOS utilities (including Apple's own `/usr/bin/caffeinate`, Amphetamine, and KeepingYouAwake) use the IOKit framework to declare system assertions:

```swift
IOPMAssertionCreateWithName(
    kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
    IOPMAssertionLevel(kIOPMAssertionLevelOn),
    "Building project" as CFString,
    &assertionID
)
```

Notice the key word: **UserIdle**. 

These assertions tell the power management root domain (`IOPMrootDomain`) that a user or background process is active, preventing the display or system from timing out due to inactivity.

However, a lid-closure is not an idle event. It is a physical hardware interrupt triggered by the Hall effect clamshell sensor. In the macOS kernel, when the clamshell sensor reports `kAppleClamshellStateKey = true`, the kernel enforces **Forced Clamshell Sleep** unless two hardware preconditions are simultaneously satisfied:
1. An AC power adapter is connected.
2. An active external display is detected.

If you don't have an external monitor plugged in, the kernel unilaterally drops all user-space `IOPMAssertion` objects and forces the SoC into low-power sleep immediately.

---

### The Dangerous Workaround: `disablesleep`

There is only one knob in macOS that overrides the kernel's clamshell sleep rule without an external display:

```sh
sudo pmset -a disablesleep 1
```

When `disablesleep` is set to `1`, the power management daemon completely ignores clamshell closure events. Your Mac stays fully awake with the lid closed.

**So why doesn't everyone just use this?**

Because it is a global, persistent state. If you toggle it manually and toss your MacBook into a padded backpack:
- Convective heat transfer through the keyboard deck is completely blocked by the closed lid.
- The laptop continues churning at 100% CPU/GPU.
- The battery quickly drains to 0%, causing deep-discharge wear on lithium-ion cells.
- Internal temperatures skyrocket, risking thermal damage to the display coating.

---

### Enter NonSleep: Fault-Tolerant Power Leases

To make closed-lid operation practical for AI coding agents and long CLI tasks, we built **NonSleep** around the concept of **Time-Bounded Leases** (inspired by Gray & Cheriton's 1989 paper on distributed cache consistency).

Instead of an imperative On/Off switch, NonSleep implements:

1. **Expiring Leases Tied to Process Lifetimes:**
When Claude Code or Cursor starts a prompt turn (via official hooks in `~/.claude/settings.json` or `~/.cursor/hooks.json`), NonSleep issues a lease containing:
- Process ID (PID)
- Kernel boot time (to prevent PID reuse attacks)
- Expiration timestamp

2. **Out-of-Band LaunchAgent Reaper:**
A lightweight LaunchAgent runs every 60 seconds (`dev.nonsleep.reaper`). If the agent process exits, crashes, or is killed via `kill -9`, the reaper automatically sweeps the orphaned lease and restores `pmset -a disablesleep 0`.

3. **Hardware Safety Cut-Outs:**
- **Battery Guard:** If battery level drops below 20%, sleep is immediately restored to prevent deep discharge.
- **Thermal Guard:** If macOS reports `IOPlatformThermalState` at `Serious` or `Critical`, NonSleep suspends the lease and allows the machine to cool down.
- **Immediate Screen Lock:** When the lid closes, NonSleep fires `pmset displaysleepnow` to ensure that an awake, closed laptop remains password-locked.

4. **Air-Gapped & Minimal Privilege:**
NonSleep contains zero network frameworks (`URLSession`, sockets). Its sudoers staging is verified via `visudo -c` and strictly restricts execution to `/usr/bin/pmset -a disablesleep 0` and `1`.

NonSleep is open source (MIT) and written in 100% native Swift:
https://github.com/Tran-Duc-Duy/nonsleep
```

---

## 2. Kịch bản Video ngắn 30s (Visual Proof Video)
*Phù hợp cho: Twitter / X, Reddit Video, YouTube Shorts, LinkedIn.*

| Giây | Hình ảnh (Visual) | Giọng đọc / Text Overlay (Audio/Text) |
| :--- | :--- | :--- |
| **0:00 - 0:05** | Quay cận cảnh màn hình MacBook: Mở terminal chạy `claude` hoặc `cursor`, gõ: *"Refactor all auth modules & run test suite"*. | *Text:* "You submit a 10-minute AI task and need to leave..." |
| **0:05 - 0:10** | Tay gập mạnh nắp MacBook lại, rút dây sạc, nhét vào balo. | *Text:* "Normal Mac: Sleeps immediately. Task cancelled." |
| **0:10 - 0:18** | Quay màn hình điện thoại đang mở SSH hoặc nhìn đèn báo: Task của Claude Code vẫn đang nhảy dòng code và chạy tests. | *Text:* "With NonSleep: Keeps running with lid closed." |
| **0:18 - 0:25** | Âm thanh `ding` vang lên (Claude Code hoàn thành). Màn hình điện thoại báo task Done $\rightarrow$ Máy tính tự động chuyển sang chế độ Sleep sâu. | *Text:* "Auto-sleeps the exact second your agent finishes." |
| **0:25 - 0:30** | Hiện logo NonSleep + GitHub URL + dòng chữ: *"Open Source • Zero Network • Pure Swift"*. | *Text:* "Free & Open Source on GitHub." |

---

## 3. Chuỗi bài đăng trên X / Twitter (Launch Thread)

**Tweet 1 (Hook):**
> macOS forces your MacBook to sleep when the lid closes unless you plug in a monitor.
> 
> This breaks Claude Code, Cursor, and long builds when you want to pack your bag and go home.
> 
> We built NonSleep: Keep your Mac running with the lid closed while your agents work, and auto-sleep when done. 🧵👇

**Tweet 2 (The Technical Problem):**
> Why does `caffeinate` fail?
> 
> `caffeinate` uses `IOPMAssertion`, which only blocks *idle* sleep. When you close the lid, macOS kernel fires a forced clamshell event that overrides all idle assertions.
> 
> The only flag that bypasses it is `pmset -a disablesleep 1`. But leaving that on manually will cook your battery in your backpack.

**Tweet 3 (The Solution):**
> NonSleep automates this safely using a lease model:
> 
> ⚡️ Hooks into Claude Code & Cursor lifecycle
> 🛡️ 60s reaper sweeps dead/crashed processes
> 🔋 Auto-sleeps if battery <20% or thermal state gets hot
> 🔒 Locks display immediately on lid close
> 🌐 100% offline, 0 dependencies, pure Swift

**Tweet 4 (CTA):**
> NonSleep is free and open-source (MIT).
> 
> Check out the architecture and code on GitHub:
> https://github.com/Tran-Duc-Duy/nonsleep
