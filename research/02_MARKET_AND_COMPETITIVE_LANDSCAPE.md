# 02. Phân tích thị trường & Đối thủ cạnh tranh (Market & Competitor Landscape)

Tài liệu so sánh chi tiết giữa NonSleep và toàn bộ các giải pháp giữ máy thức hiện có trên macOS và Linux.

---

## 1. Bảng so sánh ma trận tính năng (Feature & Safety Matrix)

| Tiêu chí | Caffeinate (Native macOS) | Amphetamine (Mac App Store) | KeepingYouAwake / Lungo | SleepLess / InsomniaX (Legacy) | **NonSleep** |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Gập nắp không cắm màn hình vẫn thức** | ❌ Tắt máy ngay | ❌ Không hỗ trợ nếu không có màn hình | ❌ Không hỗ trợ | ⚠️ Ép thức bằng Kext nguy hiểm | **✅ Hỗ trợ an toàn qua `disablesleep`** |
| **Tự động ngủ khi AI Agent kết thúc** | ❌ Không có | ❌ Không có | ❌ Không có | ❌ Không có | **✅ Hook Claude/Cursor/Codex/omp** |
| **Bảo vệ pin tự ngắt (< 20%)** | ❌ Không có | ⚠️ Chỉ có cảnh báo âm thanh | ❌ Không có | ❌ Không có | **✅ Tự động nhả lease & cho ngủ ngay** |
| **Bảo vệ quá nhiệt (Thermal cut-out)** | ❌ Không có | ❌ Không có | ❌ Không có | ❌ Không có | **✅ Ngắt cờ khi chạm ngưỡng Serious** |
| **Khóa màn hình khi gập nắp (Privacy)** | ❌ Không có | ❌ Màn hình vẫn mở quyền | ❌ Không có | ❌ Mở toang màn hình | **✅ `pmset displaysleepnow` lập tức** |
| **Cơ chế thu hồi khi crash (Failsafe Reaper)** | ❌ Không có | ❌ Rò rỉ trạng thái nếu crash | ❌ Không có | ❌ Rò rỉ Kext | **✅ LaunchAgent reaper quét mỗi 60s** |
| **Độ tin cậy bảo mật & Network** | ✅ Native Apple | ⚠️ Ứng dụng đóng (Closed-source) | ✅ Mã nguồn mở | ❌ Kernel Extension lỗi thời, mất SIP | **✅ 100% Pure Swift, Air-gapped, 0 Network** |

---

## 2. Giải mã vì sao các giải pháp hiện tại đều thất bại

### 2.1 Điểm mù của `caffeinate` và `Amphetamine`
- **Cơ chế:** Dùng API `IOPMAssertionCreateWithName(kIOPMAssertionTypePreventSystemSleep)`.
- **Lý do thất bại:** Apple định nghĩa rõ trong IOKit: Khi nắp máy gập xuống mà **không có màn hình ngoài + sạc cắm cùng lúc**, phần cứng máy tự động kích hoạt chế độ cưỡng bức ngủ (forced clamshell sleep). Toàn bộ `IOPMAssertion` trong User-space bị hạt nhân (Kernel) bỏ qua hoàn toàn.
- **Hậu quả:** Dev bật `caffeinate -d`, gập máy định đi ăn trưa $\rightarrow$ Agent chết ngắt giữa chừng, prompt chưa chạy xong.

### 2.2 Sự nguy hiểm của các công cụ cũ (`InsomniaX`, `SleepLess`)
- **Cơ chế:** Cài đặt Kernel Extension (kext) để ghi đè trình điều khiển ACPI/SMC của Apple.
- **Lý do thất bại:** Apple đã khai tử Kext từ macOS 11+. Để chạy các tool này, người dùng phải tắt System Integrity Protection (SIP) - một hành động tự sát về bảo mật.

### 2.3 Sự thiếu sót của việc gõ `sudo pmset -a disablesleep 1` bằng tay
- **Cơ chế:** Cờ duy nhất của macOS thực sự cho phép máy thức khi gập nắp không cần màn hình.
- **Rủi ro chí mạng:** Dev gõ xong, bỏ máy vào balo. Máy chạy hết công suất trong không gian kín, pin tụt về 0%, nhiệt độ linh kiện lên 80-90°C làm hỏng lớp chống lóa màn hình và chai pin.

---

## 3. Lợi thế cạnh tranh độc quyền của NonSleep (The NonSleep Moat)

```
                    ┌──────────────────────────────────────────────┐
                    │               NON-SLEEP MOAT                 │
                    └──────────────────────────────────────────────┘
                                           │
         ┌───────────────────┬─────────────┴─────────────┬───────────────────┐
         ▼                   ▼                           ▼                   ▼
┌──────────────────┐┌──────────────────┐┌──────────────────┐┌──────────────────┐
│  AI Agent Hooks  ││ Failsafe Leases  ││  Zero Network    ││  Hardware Guards │
│  Claude, Cursor, ││ 60s Reaper       ││  Air-gapped,     ││  Thermal cutoff, │
│  Codex, omp auto ││ crash-safe engine││  0 dependencies  ││  Battery <20%    │
└──────────────────┘└──────────────────┘└──────────────────┘└──────────────────┘
```

1. **Agent-Aware Đầu tiên trên thế giới:** Không yêu cầu người dùng phải tự canh giờ hay nhớ tắt. Nhận biết chính xác micro-state khi prompt đang chạy và khi prompt hoàn thành.
2. **Mô hình Lease tự dọn dẹp:** Dù máy có bị crash, kill process hay restart, hệ thống luôn tự động trở về trạng thái an toàn.
3. **Cắt quyền Sudo tối thiểu:** Chỉ cho phép 2 dòng lệnh duy nhất qua `/etc/sudoers.d/nonsleep`, không chạy background daemon dưới quyền root.
