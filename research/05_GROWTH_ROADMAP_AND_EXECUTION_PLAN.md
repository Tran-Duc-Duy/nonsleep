# 05. Lộ trình thực thi & Kế hoạch tăng trưởng (Growth Roadmap & Execution Plan)

Kế hoạch chi tiết theo từng tuần để đưa NonSleep từ 0 đến 1,000+ GitHub Stars và trở thành công cụ mặc định cho cộng đồng AI Developer.

---

## 1. Lộ trình thực thi 4 tuần (4-Week Sprint)

```
Tuần 1: Nền tảng phân phối & Cày 50 Karma Reddit
   │
   ▼
Tuần 2: Bùng nổ truyền thông kỹ thuật (Show HN & Reddit Blast)
   │
   ▼
Tuần 3: Phủ sóng hệ sinh thái (MCP Registries & Awesome Lists)
   │
   ▼
Tuần 4: Chuyển đổi thành chuẩn mặc định (Ecosystem Flywheel & B2B/Devs)
```

### Tuần 1: Hoàn thiện hạ tầng phân phối & Karma
- [ ] **Ngày 1:** Đi qua 5 link Reddit trong `REDDIT_PLAYBOOK.md`, để lại các comment chất lượng để cán mốc 50 Karma.
- [ ] **Ngày 2:** Tạo repo `Tran-Duc-Duy/homebrew-tap`, đưa file `Casks/nonsleep.rb` lên để người dùng có thể cài qua `brew install --cask`.
- [ ] **Ngày 3:** Đăng ký NonSleep lên các chợ MCP: Smithery.ai và Glama.ai.
- [ ] **Ngày 4:** Kiểm tra toàn bộ luồng cài đặt từ `brew` trên một máy Mac sạch hoặc qua VM/tài khoản test.

### Tuần 2: Bùng nổ truyền thông (Launch Week)
- [ ] **Thứ Ba (8:00 AM EST):** Đăng **Show HN** lên Hacker News (Dùng mẫu tiêu đề và bài viết mở màn trong file `03_DISTRIBUTION_AND_CHANNELS.md`).
- [ ] **Thứ Ba (10:00 AM EST):** Khi bài Show HN bắt đầu có upvote, đăng bài chính thức lên `r/ClaudeAI` và `r/macapps` (đã đủ 50 Karma).
- [ ] **Thứ Tư:** Đăng bài phân tích chuyên sâu *"Why macOS Ignores Caffeinate..."* lên **Dev.to** và **Medium**.
- [ ] **Thứ Năm:** Đăng chuỗi bài Thread trên **X / Twitter** kèm video demo 30s hoặc ảnh chụp trực quan.
- [ ] **Thứ Sáu:** Trực tiếp trả lời từng câu hỏi kỹ thuật trên Hacker News và Reddit (tập trung giải thích mô hình Lease và tính an toàn của sudoers).

### Tuần 3: Backlink & Thư viện nguồn mở
- [ ] Gửi Pull Request vào `jaywcjlove/awesome-mac`.
- [ ] Gửi Pull Request vào `serhii-londar/open-source-mac-os-apps`.
- [ ] Gửi Pull Request vào `punkpeye/awesome-mcp-servers`.
- [ ] Tham gia Discord của Cursor (`r/cursor` community) và Aider, chia sẻ NonSleep ở kênh `#tools-and-showcase`.

### Tuần 4: Đo lường & Hoàn thiện tính năng sinh thái
- [ ] Đánh giá lượng clone và traffic trong GitHub Insights.
- [ ] Thu thập feedback từ các issues và comments để tối ưu trải nghiệm (ví dụ: tự động phát hiện thêm các agent mới như Goose, OpenHands).

---

## 2. Bảng theo dõi chỉ số mục tiêu (Target KPIs)

| Chỉ số | Mục tiêu Tuần 2 | Mục tiêu Tuần 4 | Phương pháp đo lường |
| :--- | :---: | :---: | :--- |
| **Reddit Karma** | $\ge 50$ | $150+$ | Kiểm tra trên hồ sơ Reddit |
| **GitHub Stars** | $100+$ | $500+$ | GitHub Repository Insights |
| **Homebrew Installs** | $50+$ | $300+$ | Homebrew Analytics / GitHub Release downloads |
| **Hacker News Rank** | Top 20 Show HN | — | Hacker News Frontpage |
| **MCP Registry Views** | $200+$ | $1,000+$ | Smithery / Glama dashboard |

---

## 3. Checklist nguyên tắc ứng xử khi trả lời phản biện (Defense Rules)

Khi đăng bài ở HN hoặc Reddit, sẽ có 3 câu hỏi kinh điển được đặt ra. Đây là câu trả lời chuẩn:

1. **"Tại sao không dùng Amphetamine cho nhanh?"**
   $\rightarrow$ *Trả lời:* Amphetamine dùng `IOPMAssertion`, macOS sẽ cưỡng bức ngủ ngay khi gập nắp nếu không có màn hình ngoài. NonSleep là công cụ duy nhất quản lý cờ `disablesleep` an toàn bằng lease.
2. **"Tại sao app lại cần quyền Sudo?"**
   $\rightarrow$ *Trả lời:* Quyền sudo được giới hạn tuyệt đối qua `/etc/sudoers.d/nonsleep`, chỉ cho phép chạy đúng 2 lệnh `pmset -a disablesleep 0` và `1`. Không có daemon nào chạy ngầm dưới quyền root.
3. **"Có nguy cơ máy bị quá nhiệt trong balo không?"**
   $\rightarrow$ *Trả lời:* NonSleep tích hợp sẵn cơ chế ngắt phần cứng: tự động tắt và cho máy ngủ ngay lập tức nếu nhiệt độ đạt ngưỡng Serious hoặc pin dưới 20%.
