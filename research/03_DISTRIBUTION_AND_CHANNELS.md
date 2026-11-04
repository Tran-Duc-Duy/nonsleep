# 03. Thiết kế kênh phân phối & Tăng trưởng (Distribution & Growth Channels)

Tài liệu hướng dẫn triển khai từng kênh phân phối để biến NonSleep thành công cụ mặc định cho mọi AI developer.

---

## 1. Kênh Homebrew (Giảm thiểu 95% rào cản cài đặt)

Người dùng Mac không thích tải `.zip` rồi mò vào Settings ấn "Open Anyway". Cài qua `brew` là tiêu chuẩn của giới kỹ thuật.

### 1.1 Khởi tạo GitHub Repo Tap riêng
Tạo một repository mới trên GitHub: `Tran-Duc-Duy/homebrew-tap`

### 1.2 Viết Formula Cask (`Casks/nonsleep.rb`)
```ruby
cask "nonsleep" do
  version "1.0.0" # Cập nhật theo tag release thực tế
  sha256 "SHA256_CỦA_FILE_ZIP_TRÊN_RELEASE"

  url "https://github.com/Tran-Duc-Duy/nonsleep/releases/download/v#{version}/NonSleep-#{version}-macOS.zip"
  name "NonSleep"
  desc "Keep Mac awake with lid closed while AI agents run, auto-sleep when finished"
  homepage "https://github.com/Tran-Duc-Duy/nonsleep"

  depends_on macos: ">= :ventura"

  app "NonSleep.app"
  binary "#{appdir}/NonSleep.app/Contents/MacOS/nonsleep", target: "nonsleep"

  postflight do
    system_command "#{appdir}/NonSleep.app/Contents/MacOS/nonsleep",
                   args: ["setup"],
                   sudo: true
  end

  uninstall_preflight do
    system_command "#{appdir}/NonSleep.app/Contents/MacOS/nonsleep",
                   args: ["setup", "--remove"],
                   sudo: true
  end

  zap trash: [
    "~/Library/Application Support/NonSleep",
    "~/Library/LaunchAgents/dev.nonsleep.reaper.plist",
  ]
end
```
Sau đó người dùng chỉ cần gõ 1 dòng lệnh duy nhất:
```sh
brew install --cask Tran-Duc-Duy/tap/nonsleep
```

---

## 2. Kênh Hacker News (Show HN Launch Blueprint)

Hacker News là bệ phóng lớn nhất cho dev tools. Đạt top 10 Show HN sẽ mang lại từ 300 đến 1,000 GitHub stars trong 24 giờ.

### 2.1 Thời điểm vàng đăng bài
- **Thứ Ba hoặc Thứ Tư:** Lúc 8:00 AM - 9:00 AM EST (khoảng 8:00 PM - 9:00 PM giờ Việt Nam). Đây là lúc các kỹ sư Thung lũng Silicon bắt đầu ngày làm việc.

### 2.2 Tiêu đề chuẩn Hacker News
```text
Show HN: NonSleep – Keep your Mac running with lid closed while AI agents work
```

### 2.3 Bài viết mở màn (Opening Comment của tác giả)
```markdown
Hi HN,

I built NonSleep because I was constantly frustrated that closing my MacBook lid killed active Claude Code and Cursor runs on my commute home.

A lot of developers assume `caffeinate` or Amphetamine solves this. But as soon as the lid closes without both AC power and an external monitor attached, macOS intentionally ignores user-space `IOPMAssertion` calls and forces clamshell sleep. 

The only switch that actually works is `sudo pmset -a disablesleep 1`. But leaving that on manually risks cooking your battery in a backpack.

NonSleep treats sleep prevention as a time-bounded lease (inspired by Gray & Cheriton '89):
1. **Agent-Aware:** Hooks directly into Claude Code (`~/.claude/settings.json`) and Cursor (`~/.cursor/hooks.json`). When a prompt starts, it acquires a lease. When the prompt ends, it releases the lease and lets macOS sleep immediately.
2. **Crash-Safe Reaper:** A LaunchAgent reaper checks every 60s. If an agent crashes or dies, normal sleep is automatically restored.
3. **Safety Cut-outs:** Automatically suspends and sleeps if battery drops <20% or thermal throttling triggers.
4. **Air-Gapped & Minimal Privilege:** 100% pure Swift, 0 remote dependencies, zero network calls. The sudoers rule allows strictly `/usr/bin/pmset -a disablesleep 0/1`.

GitHub: https://github.com/Tran-Duc-Duy/nonsleep

Would love to hear your thoughts, feedback on the lease model, and edge cases!
```

---

## 3. Kênh Model Context Protocol (MCP Registry)

NonSleep có sẵn lệnh `nonsleep mcp`. Cần niêm yết lên các chợ MCP chính thức:

### 3.1 Danh sách Registry cần nộp:
1. **Smithery.ai** (`smithery.json`): Chợ MCP lớn nhất cho Claude Desktop.
2. **Glama.ai** (`glama.json`): Registry cho Cursor & Zed.
3. **mcp.so**: Thư mục công cụ MCP cộng đồng.
4. **GitHub `punkpeye/awesome-mcp-servers`**: Nộp Pull Request vào mục *Operating System Utilities*.

### 3.2 File cấu hình MCP mẫu cho người dùng thêm vào Claude Desktop (`claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "nonsleep": {
      "command": "nonsleep",
      "args": ["mcp"]
    }
  }
}
```

---

## 4. Kênh GitHub Awesome Lists (Backlink & SEO Traffic)

Tạo PR nộp vào các danh sách uy tín sau:

1. **`jaywcjlove/awesome-mac`**: Mục *Developer Tools / Utilities*.
2. **`serhii-londar/open-source-mac-os-apps`**: Mục *Utilities* (Repo này có >40k stars, lượng traffic đổ về rất lớn).
3. **`steipete/awesome-claude-code`**: Danh sách tài nguyên cho Claude Code CLI.
4. **`awesome-cursorrules`**: Thêm hướng dẫn mẫu tự động bật NonSleep khi Cursor chạy tác vụ ngầm.
