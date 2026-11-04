# NonSleep — Reddit Promotion & Engagement Playbook

Tài liệu tổng hợp các mẫu bài đăng (Posts) và bình luận (Comments) chuẩn phong cách cộng đồng kỹ thuật Reddit. Các mẫu được định dạng sẵn trong code block để sao chép trực tiếp.

---

## Mục lục
1. [Phần 1: Bộ mẫu cày nhanh 50 Karma (Karma Farming)](#phần-1-bộ-mẫu-cày-nhanh-50-karma)
2. [Phần 2: Bài đăng chính thức (Show Reddit Posts)](#phần-2-bài-đăng-chính-thức-show-reddit-posts)
   - [2.1 Dành cho r/ClaudeAI](#21-dành-cho-rclaudeai)
   - [2.2 Dành cho r/cursor](#22-dành-cho-rcursor)
   - [2.3 Dành cho r/macapps & r/commandline](#23-dành-cho-rmacapps--rcommandline)
   - [2.4 Dành cho r/LocalLLaMA](#24-dành-cho-rlocalllama)
3. [Phần 3: Mẫu comment dạo theo ngữ cảnh (Contextual Comments)](#phần-3-mẫu-comment-dạo-theo-ngữ-cảnh)
4. [Phần 4: Check-list bảo vệ tài khoản & Tránh Shadowban](#phần-4-check-list-bảo-vệ-tài-khoản)

---

## 🔥 Danh sách Link thớt Reddit đang có sẵn (Bấm vào là cmt được ngay)

| Nhóm | Link thớt Reddit | Nội dung cần cmt |
| :--- | :--- | :--- |
| **Direct Target** | [r/MacOS: Prevent sleep when lid is closed (no screen)](https://www.reddit.com/r/MacOS/comments/1qk6v5q/prevent_sleep_when_macbook_lid_is_closed_no_screen/) | [Mục Link 1](#link-1-rmacos-prevent-sleep-when-lid-closed) |
| **Direct Target** | [r/MacOSApps: CaffeinateCat keep Mac awake with lid closed](https://www.reddit.com/r/MacOSApps/comments/1upsqjp/caffeinatecat_keep_your_mac_awake_with_the_lid/) | [Mục Link 2](#link-2-rmacosapps-caffeinate-clamshell) |
| **Claude Code** | [r/ClaudeAI: Claude Code hooks discussion](https://www.reddit.com/r/ClaudeAI/comments/1qlzxr1/claude_codes_most_underrated_feature_hooks_wrote/) | [Mục Link 3](#link-3-rclaudeai-claude-code-hooks) |
| **Mac Apps FOSS** | [r/macapps: Keyboard-first must-have macOS apps](https://www.reddit.com/r/macapps/comments/1qkuxbk/keyboardfirst_app_users_what_are_your_musthave/) | [Mục Link 4](#link-4-rmacapps-must-have-apps) |
| **Productivity** | [r/macapps: Must-Have Tools for productivity](https://www.reddit.com/r/macapps/comments/1iacxul/my_musthavetools_list_for_productivity_anything/) | [Mục Link 5](#link-5-rmacapps-productivity-tools) |

---
### Link 1: r/MacOS — Prevent sleep when lid is closed (no screen)
🔗 **Link:** https://www.reddit.com/r/MacOS/comments/1qk6v5q/prevent_sleep_when_macbook_lid_is_closed_no_screen/

```markdown
The reason tools like `caffeinate` don't work here is that macOS distinguishes between *idle sleep* and *clamshell sleep*. `caffeinate` creates an `IOPMAssertion`, but the kernel's lid-closed sensor intentionally overrides all idle assertions unless you have an external display and AC power plugged in.

The only system switch that bypasses lid-sleep without an external display is:
```sh
sudo pmset -a disablesleep 1
```

Just remember to turn it back off (`sudo pmset -a disablesleep 0`), otherwise you risk cooking your laptop in a backpack. 

If you prefer an automated solution that binds `disablesleep` to running processes/agents with automatic battery (<20%) and thermal cut-offs, I built an open-source tool called NonSleep: https://github.com/Tran-Duc-Duy/nonsleep (Disclaimer: I am the developer).
```

---

### Link 2: r/MacOSApps — CaffeinateCat keep Mac awake with lid closed
🔗 **Link:** https://www.reddit.com/r/MacOSApps/comments/1upsqjp/caffeinatecat_keep_your_mac_awake_with_the_lid/

```markdown
Nice to see more utilities solving the closed-lid problem! 

The biggest risk with toggling `pmset -a disablesleep 1` has always been safety cut-outs: if a user forgets to re-enable sleep or slips the MacBook into a sleeve while a background task runs hot, there's no native safeguard.

In NonSleep (an open-source project I built for coding agents and long CLI tasks: https://github.com/Tran-Duc-Duy/nonsleep), we addressed this with a 60s LaunchAgent reaper, auto-sleep if battery drops <20%, thermal throttling cut-outs, and triggering `pmset displaysleepnow` to ensure the screen locks instantly on lid close.

How do you guys handle the safety cut-out when the Mac is in a bag or runs low on battery?
```

---

### Link 3: r/ClaudeAI — Claude Code hooks discussion
🔗 **Link:** https://www.reddit.com/r/ClaudeAI/comments/1qlzxr1/claude_codes_most_underrated_feature_hooks_wrote/

```markdown
Completely agree on hooks being the most underrated feature. Moving enforcement from system prompt/CLAUDE.md to deterministic lifecycle hooks changes the reliability completely.

One area where hooks shine is tying agent lifecycle events to system state. For instance, hooking `UserPromptSubmit` and `Stop` to keep your machine awake while a long prompt runs with the lid closed, then restoring sleep the second Claude finishes (`Stop`/`SessionEnd`). 

Also, having desktop alerts via `osascript` on `Stop` saves so much time compared to babysitting the terminal.
```

---

### Link 4: r/macapps — Keyboard-first must-have macOS apps
🔗 **Link:** https://www.reddit.com/r/macapps/comments/1qkuxbk/keyboardfirst_app_users_what_are_your_musthave/

```markdown
For a keyboard-first workflow on macOS without bloated Electron apps:

1. **Raycast** – Essential for launcher, custom bash scripts, and hotkeys.
2. **Maccy** – Native, keyboard-navigable clipboard manager (`Cmd+Shift+C`, numbers to select, fuzzy search).
3. **AeroSpace** or **Yabai** – Tiling window managers that allow full i3-style keyboard workspace navigation.
4. **Shottr** – Fast screenshot tool with complete keyboard shortcuts for annotations and pin-to-screen.
5. **Ghostty** or **Alacritty** – GPU-accelerated terminal emulators with native keybinding support.
```

---

### Link 5: r/macapps — Must-Have Tools for productivity
🔗 **Link:** https://www.reddit.com/r/macapps/comments/1iacxul/my_musthavetools_list_for_productivity_anything/

```markdown
Solid list! A few lightweight, open-source utilities worth adding that respect system resources:

- **Pearcleaner**: Completely open-source app cleaner that sweeps residual Library files without a background daemon.
- **Ice**: Open-source menu bar manager to keep the notch/status bar clean.
- **Maccy**: Minimalist clipboard history with zero latency.
- **Keka**: Lightweight archiver for 7z/tar/rar.

All free, zero telemetry, and pure native.
```

---


## Phần 1: Bộ mẫu cày nhanh 50 Karma

Mục tiêu: Đạt 50 Karma tự nhiên bằng cách đóng góp câu trả lời có giá trị thực, không gắn link quảng cáo.

### 1.1 Thớt "Free / Open-Source Mac Apps" trên `r/macapps`
* **Nơi đăng:** Vào `reddit.com/r/macapps`, tìm các thớt hỏi *"What are your favorite free apps?"* hoặc *"Must-have utilities for a new Mac"*.

```markdown
Here are a few lightweight, open-source utilities I install on every new Mac that don't bloat the system:

1. **Maccy** – Minimal, native clipboard manager with zero lag and great keyboard navigation.
2. **Ice** – Clean and modern menu bar manager to hide clutter (a great open-source alternative to Bartender).
3. **Pearcleaner** – Open-source app uninstaller that cleanly sweeps leftover Library files without running background daemons.
4. **Keka** – Powerful archive extractor (handles 7z, rar, tar.gz effortlessly).
5. **Raycast** – Replaces Spotlight entirely; the custom script commands and window management are unmatched.
6. **IINA** – Modern open-source video player built specifically for macOS with mpv under the hood.

All of these are completely free/open-source with no telemetry or tracking bloat.
```

---

### 1.2 Thớt "Caffeinate / Clamshell sleep" trên `r/MacOS`
* **Nơi đăng:** Vào `reddit.com/r/MacOS`, tìm các thớt hỏi về *"Why does caffeinate fail on lid close?"* hoặc *"Keep Mac awake without external monitor"*.

```markdown
`caffeinate` doesn't work when you close the lid because it only creates an `IOPMAssertion` (such as `PreventUserIdleSystemSleep`). 

macOS power management intentionally ignores all idle assertions when a physical clamshell event (lid close) is triggered, unless two strict criteria are met:
1. Connected to an AC power adapter.
2. Connected to an active external display.

Without an external screen, the only native system switch that overrides lid-sleep is:
```sh
sudo pmset -a disablesleep 1
```

Just be cautious: if you pack your MacBook into a bag while `disablesleep` is active, it won't sleep even if it starts overheating. Always remember to turn it back to normal:
```sh
sudo pmset -a disablesleep 0
```
```

---

### 1.3 Thớt hỏi mẹo dùng Claude Code / Cursor trên `r/ClaudeAI` hoặc `r/cursor`
* **Nơi đăng:** Các thớt thảo luận về tips, background scripts, workflow.

```markdown
One handy tip if you run multi-turn agent sessions or long builds in Claude Code / Cursor:

Take advantage of the command hooks (`~/.claude/settings.json` or `~/.cursor/hooks.json`). You can attach lightweight shell triggers to events like `PostToolUse` or `Stop` to send desktop notifications (via `osascript -e 'display notification ...'`) or chime when a long prompt completes.

Saves you from constantly switching tabs or checking terminal status while working on something else.
```

---

### 1.4 Mẹo cày 50 Karma trong 30-60 phút trên `r/AskReddit`
* **Cách làm:** Vào `reddit.com/r/AskReddit/rising` (tab **Rising** là các bài đang tăng tương tác, comment sớm sẽ nổi lên top).

* **Gặp câu hỏi về thói quen cuộc sống:**
```text
The 2-minute rule. If a task takes less than two minutes (washing a mug, replying to a quick email, taking out the trash), do it right away instead of letting it occupy mental bandwidth.
```

* **Gặp câu hỏi về lập trình / IT:**
```text
Never push a Friday afternoon deployment to production unless you genuinely despise your weekend and your coworkers.
```

* **Gặp câu hỏi về công nghệ ấn tượng:**
```text
Active Noise Cancellation. The fact that miniature microphones sample complex ambient sound waves and generate an inverted phase waveform in real-time with near-zero latency still feels like sorcery.
```

---

## Phần 2: Bài đăng chính thức (Show Reddit Posts)

---

### 2.1 Dành cho `r/ClaudeAI`

* **Flair:** `Project / Showcase` hoặc `Discussion`
* **Title:**
```text
I built an open-source tool to let Claude Code finish running with your MacBook lid closed (and auto-sleep when done)
```

* **Body:**
```markdown
If you've tried running long prompt turns on Claude Code and closed your MacBook lid to head home, you've probably noticed that macOS forces sleep immediately unless an external monitor is plugged in.

Standard tools like `caffeinate` or Amphetamine rely on `IOPMAssertion`, which Apple intentionally ignores on lid close in clamshell mode without an external display. The only system switch that bypasses this is:
`sudo pmset -a disablesleep 1`

The problem with running that manually is forgetting it, packing the MacBook into a backpack, and having it cook the battery to 0%.

I built **NonSleep** (macOS 13+ & Linux) to automate this safely:

- **Claude Code integration**: Uses Claude Code's official hooks (`~/.claude/settings.json`) to detect when a prompt turn starts (`UserPromptSubmit`, `PostToolUse`) and ends (`Stop`, `SessionEnd`). It holds sleep off while Claude is working and restores sleep the exact second it finishes.
- **Zero-network & Zero-dependency**: 100% pure Swift, no external packages, completely air-gapped (no `URLSession`, zero telemetry).
- **Failsafe reaper**: Every wake request is a lease tied to a PID and timeout. A background reaper LaunchAgent (`dev.nonsleep.reaper`) sweeps every 60s. If Claude crashes or finishes, sleep is automatically restored.
- **Hardware cut-outs**: Automatically aborts and sleeps if battery drops below 20% or thermal state hits serious/critical levels.
- **Instant screen lock**: Triggers `pmset displaysleepnow` when the lid closes so your machine stays locked.

**Regarding permissions:**
It configures a minimal sudoers rule strictly limited to `/usr/bin/pmset -a disablesleep 0` and `1` (validated via `visudo -c`). No persistent daemon running as root.

It's free and open-source (MIT):
GitHub: https://github.com/Tran-Duc-Duy/nonsleep

Would love to hear your feedback, thoughts on the architecture, or bug reports!
```

---

### 2.2 Dành cho `r/cursor`

* **Flair:** `Discussion` hoặc `Showcase`
* **Title:**
```text
Keep Cursor running long background tasks with your MacBook lid closed (open-source tool)
```

* **Body:**
```markdown
Whenever I trigger a large refactoring task or long agent command in Cursor Composer and close my laptop to commute, macOS immediately forces sleep (unless an external monitor + charger are plugged in).

Tools like `caffeinate` don't help here because clamshell sleep ignores `IOPMAssertion`.

I built **NonSleep** to solve this:
- **Cursor Hooks**: Integrates with `~/.cursor/hooks.json` (`beforeSubmitPrompt`, `postToolUse`, `stop`, `sessionEnd`).
- **Hands-off**: Keeps your Mac awake while Cursor is active, and automatically lets macOS sleep the moment the agent finishes.
- **Safety Cut-outs**: Auto-sleeps if battery drops below 20% or if thermal state becomes serious, preventing battery drain in your bag.
- **Immediate Screen Lock**: Automatically locks your display on lid close for security.
- **Air-gapped**: Zero dependencies, 100% native Swift, no network calls or telemetry.

GitHub (MIT): https://github.com/Tran-Duc-Duy/nonsleep

Feedback and feature requests are very welcome!
```

---

### 2.3 Dành cho `r/macapps` & `r/commandline`

* **Flair on r/macapps:** `Show macapps`
* **Title:**
```text
[Show macapps] NonSleep: Why caffeinate fails on closed lid, and how I fixed it with a safe lease-based pmset manager (Open Source, Pure Swift)
```

* **Body:**
```markdown
**The Problem:**
A common frustration among macOS developers is keeping long builds, downloads, or local scripts running with the MacBook lid closed. Standard utilities like `caffeinate` or Amphetamine rely on `IOPMAssertionCreateWithName`. Apple intentionally disregards these assertions on lid close unless the machine is plugged into both power and an external monitor.

The only system flag that keeps a closed lid awake without an external screen is:
`sudo pmset -a disablesleep 1`

However, toggling this manually is dangerous: if you forget to turn it off and slip your laptop into a sleeve, it can overheat and drain the battery to 0%.

**How NonSleep Works:**
I built **NonSleep** as a native Menu Bar app + CLI in pure Swift with 0 dependencies:

1. **Lease Engine**: Any task creates an expiring lease (`nonsleep run -- npm build`, `nonsleep on 45m`, `nonsleep wait <PID>`, or automated coding agent hooks).
2. **LaunchAgent Reaper**: Runs every 60s. If the owning process exits, crashes, or times out, normal sleep (`disablesleep 0`) is restored automatically.
3. **Safety Guards**: Pauses and allows sleep if battery drops under 20% or thermal throttling triggers.
4. **Privacy**: Locks display immediately on lid close via `pmset displaysleepnow`.
5. **Minimal Sudo Scope**: Staged with `visudo -c` and restricted exclusively to toggling `pmset -a disablesleep 0` and `1`.

It is completely air-gapped (no network imports, zero analytics).

GitHub (Source code, architecture docs, releases):
https://github.com/Tran-Duc-Duy/nonsleep

Happy to answer any technical questions about the IOKit implementation or process tracking!
```

---

### 2.4 Dành cho `r/LocalLLaMA`

* **Flair:** `Discussion` hoặc `Resource`
* **Title:**
```text
Run local models/scripts on your MacBook with the lid closed without cooking your battery (open-source tool)
```

* **Body:**
```markdown
If you run long local inference, fine-tuning scripts, or Ollama jobs on your MacBook, you've likely hit the clamshell limitation: macOS sleeps the moment the lid closes unless you have an external monitor connected.

`caffeinate` doesn't work for closed lids because clamshell sleep bypasses `IOPMAssertion`.

I made **NonSleep**, an open-source CLI & menu bar utility designed for this exact use case:
- Run any command: `nonsleep run -- ollama run ...` or `nonsleep wait <PID>`. The Mac stays awake with the lid closed, then sleeps immediately when the process terminates.
- Built-in thermal and battery cut-offs (<20%) to avoid overheating in a bag.
- Air-gapped (pure Swift, 0 network dependencies).

GitHub: https://github.com/Tran-Duc-Duy/nonsleep (MIT)
```

---

## Phần 3: Mẫu comment dạo theo ngữ cảnh

Áp dụng quy tắc **3 bước**:
1. Trả lời nguyên nhân kỹ thuật trước.
2. Cung cấp lệnh native của macOS (`pmset`).
3. Đề xuất NonSleep như giải pháp tự động (kèm disclaimer minh bạch).

### 3.1 Khi người khác hỏi: *"Why does my Mac sleep when I close the lid even with caffeinate?"*
```markdown
That's because `caffeinate` only sets an `IOPMAssertion`, which blocks idle sleep. macOS intentionally ignores idle assertions when the lid closes unless you have both an external display and AC power plugged in.

The only native command that forces a Mac to stay awake with the lid closed on battery or without a monitor is:
```sh
sudo pmset -a disablesleep 1
```
*(Remember to run `sudo pmset -a disablesleep 0` when done, otherwise it will continue running hot in your bag).*

If you want an automated tool that ties this to your running scripts/agents with thermal/battery protection, I built an open-source tool called NonSleep: https://github.com/Tran-Duc-Duy/nonsleep (Disclaimer: I am the developer).
```

---

### 3.2 Khi người khác hỏi: *"How to run Claude Code / Cursor while commuting with laptop closed?"*
```markdown
The main issue is that macOS clamshell mode requires an external monitor by default, so closing the lid interrupts your agent's active turn.

You can either manually toggle `sudo pmset -a disablesleep 1`, or automate it via agent hooks.

I created an open-source tool called NonSleep (https://github.com/Tran-Duc-Duy/nonsleep) that hooks directly into Claude Code (`~/.claude/settings.json`) and Cursor. It turns disablesleep on while a prompt turn is actively running, and immediately restores normal sleep the second the turn finishes. Has battery and thermal cutouts as well. (Full disclosure: I built it).
```

---

### 3.3 Từ khóa tìm kiếm thớt thảo luận trên Reddit/Google
Gõ vào ô search của Reddit hoặc Google:
- `site:reddit.com/r/macos "caffeinate" "lid closed"`
- `site:reddit.com/r/macapps "clamshell" "without monitor"`
- `site:reddit.com/r/ClaudeAI "sleep" OR "macbook"`
- `site:reddit.com/r/cursor "background" "sleep" OR "lid"`
- `site:reddit.com/r/macos "pmset disablesleep"`

---

## Phần 4: Check-list bảo vệ tài khoản

1. **Quy tắc 9:1:** Cứ 10 comment chỉ có tối đa 1 comment nhắc tới NonSleep. 9 comment còn lại hãy thảo luận kỹ thuật bình thường để tài khoản có trust.
2. **Không spam link hàng loạt:** Không đăng bài lên nhiều hơn 2 subreddits trong cùng 1 ngày.
3. **Bắt buộc có Disclaimer:** Khi dẫn link sản phẩm của mình, luôn thêm: `(Disclaimer: I built this open-source tool)`.
4. **Giải thích rõ về Gatekeeper khi người dùng thắc mắc:**
   - Khi ai đó hỏi về cảnh báo unnotarized app: Hướng dẫn họ dùng lệnh bỏ quarantine (`xattr -dr com.apple.quarantine NonSleep.app`), kiểm tra SLSA build provenance (`gh attestation verify`), hoặc tự build từ source (`scripts/install.sh`). Tính minh bạch này sẽ tạo được uy tín rất lớn trong mắt cộng đồng open-source.
