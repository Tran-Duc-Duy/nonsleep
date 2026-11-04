# NonSleep — Research & Growth Intelligence Hub

Thư mục này chứa toàn bộ tài liệu nghiên cứu học thuật, phân tích thị trường, chiến lược phân phối và nội dung truyền thông cho dự án **NonSleep**.

---

## Cấu trúc tài liệu

```
research/
├── 01_SCIENTIFIC_FOUNDATIONS.md        # Cơ sở khoa học: Mô hình Lease, Nhiệt động học gập nắp, Động học pin Li-ion
├── 02_MARKET_AND_COMPETITIVE_LANDSCAPE.md # Phân tích đối thủ: Caffeinate, Amphetamine, Kext legacy
├── 03_DISTRIBUTION_AND_CHANNELS.md    # Kênh phân phối: Homebrew Cask, Hacker News, MCP Registry, Awesome Lists
├── 04_CONTENT_AND_COPYWRITING_ENGINE.md # Bài viết kỹ thuật sâu, Kịch bản video 30s, Thread X/Twitter
├── 05_GROWTH_ROADMAP_AND_EXECUTION_PLAN.md # Lộ trình 4 tuần, Chỉ số KPI, Checklist phản biện
├── 06_USER_REPORTED_ISSUES.md          # Phản hồi thực tế: nóng máy khi gập nắp, rớt hotspot 4G
└── 07_REDDIT_PLAYBOOK.md               # Link thớt Reddit có sẵn, mẫu post và comment copy-paste
```

---

## Tóm tắt nhanh giá trị cốt lõi

1. **Nền tảng lý thuyết vững chắc:** NonSleep giải quyết vấn đề trạng thái toàn cục bằng **Mô hình Lease có giới hạn thời gian** (Gray & Cheriton, 1989), loại bỏ hoàn toàn nguy cơ rò rỉ trạng thái khi agent bị crash hoặc kill.
2. **Bảo vệ phần cứng dựa trên vật lý:** Ngăn chặn hiện tượng bẫy nhiệt khi gập nắp và hiện tượng lão hóa pin phi tuyến tính bằng cơ chế ngắt nhiệt độ (Thermal cut-out) và ngắt pin (<20% Battery cut-out).
3. **Phân phối không rào cản:** Thiết kế phân phối qua Homebrew Cask (`brew install --cask nonsleep`) và chợ MCP chính thức (Smithery, Glama) để tiếp cận trực tiếp các lập trình viên sử dụng Claude Code, Cursor, và các công cụ AI CLI.
