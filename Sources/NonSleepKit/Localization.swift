import Foundation

/// Languages the interface is translated into. `auto` follows the system.
///
/// No `.lproj` bundles: `Package.swift` declares no resources and `build-app.sh` assembles the
/// app bundle by hand, so a resource bundle would be one more thing to get wrong at package time.
/// A compiled-in table also lets the CLI and the app share exactly one set of strings.
public enum Language: String, Codable, Sendable, CaseIterable, Identifiable {
    case auto, en, vi

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .auto: "System"
        case .en: "English"
        case .vi: "Tiếng Việt"
        }
    }

    /// The language actually used for lookups: `auto` resolves against the system's preferences,
    /// falling back to English for anything we don't translate.
    public var resolved: Language {
        guard self == .auto else { return self }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("vi") ? .vi : .en
    }
}

/// Every piece of user-facing text, keyed by case so a missing translation is a compile error
/// rather than a string that silently falls back to English at runtime.
public enum L10n: Sendable {
    // Status
    case statusStarting
    case statusPaused(String)
    case statusOtherTool
    case statusAwake
    case statusNormal
    case blockerBattery(Int, Int)
    case blockerThermal(String)
    case blockerBackpack(String)
    case manualUntil(String), manualUntilOff

    // Power facts
    case lidClosed, lidOpen, onBattery, onAC, externalDisplay
    case thermalState(String)

    // Menu + window actions
    case keepAwake, forOneHour, forThreeHours, forEightHours, untilTurnedOff
    case customDuration, turnOff, sleepNow, setTimer, cancel, release
    case openNonSleep, quitNonSleep, autoWhileAgentsWork, agentsLabel
    case finishSetup, openConfigFile, securityPolicy

    // Window sections
    case sectionKeepingAwake, sectionAgents, sectionIntegrations, sectionSettings, sectionSetup

    // Window body
    case noLeases, noAgentWorking, autoPausedUntilWake
    case customDurationPrompt, customDurationExamples, customDurationHelp, sleepNowHelp, releaseHelp
    case ompBuiltIn, hooksIn(String), hooksExplanation(Int)

    // Settings
    case settingAuto, settingLockOnLidClose, settingLockOnLidCloseHelp
    case settingSleepWhenDone, settingSleepWhenDoneHelp
    case settingMinBattery(Int), settingMinBatteryHelp
    case settingGrace(String), settingGraceHelp
    case settingAssertions, settingAssertionsPrompt
    case settingProcesses, settingProcessesPrompt, settingProcessesHelp
    case settingLaunchAtLogin, settingSound, settingSoundHelp
    case settingBackpack, settingBackpackHelp
    case settingLanguage

    // Setup checks
    case setupSudoers, setupReaper, setupReaperDetail
    case setupScreenLock(String), setupScreenLockDetail
    case setupAdminPrompt, setupOfflineNote

    public func callAsFunction(_ language: Language = .auto) -> String {
        string(language)
    }

    public func string(_ language: Language = .auto) -> String {
        switch language.resolved {
        case .vi: vietnamese
        default: english
        }
    }

    private var english: String {
        switch self {
        case .statusStarting: "Starting…"
        case .statusPaused(let why): "Paused: \(why)"
        case .statusOtherTool: "Sleep disabled by another tool"
        case .statusAwake: "Stays awake with the lid closed"
        case .statusNormal: "Normal sleep"
        case .blockerBattery(let percent, let minimum): "battery \(percent)% < \(minimum)%"
        case .blockerThermal(let state): "thermal state \(state)"
        case .blockerBackpack(let state): "backpack protection: thermal state \(state) with closed lid on battery"
        case .manualUntil(let time): "Manual until \(time)"
        case .manualUntilOff: "Manual until turned off"

        case .lidClosed: "Lid closed"
        case .lidOpen: "Lid open"
        case .onBattery: "Battery"
        case .onAC: "AC"
        case .externalDisplay: "External display"
        case .thermalState(let state): "Thermal \(state)"

        case .keepAwake: "Keep awake"
        case .forOneHour: "For 1 hour"
        case .forThreeHours: "For 3 hours"
        case .forEightHours: "For 8 hours"
        case .untilTurnedOff: "Until turned off"
        case .customDuration: "Custom duration…"
        case .turnOff: "Turn off"
        case .sleepNow: "Sleep now"
        case .setTimer: "Set timer"
        case .cancel: "Cancel"
        case .release: "Release"
        case .openNonSleep: "Open NonSleep…"
        case .quitNonSleep: "Quit NonSleep"
        case .autoWhileAgentsWork: "Auto: while agents are working"
        case .agentsLabel: "Agents"
        case .finishSetup: "Finish setup…"
        case .openConfigFile: "Open config.json"
        case .securityPolicy: "Security Policy"

        case .sectionKeepingAwake: "Keeping the Mac awake"
        case .sectionAgents: "Agents"
        case .sectionIntegrations: "Integrations"
        case .sectionSettings: "Settings"
        case .sectionSetup: "Setup"

        case .noLeases: "Nothing. Closing the lid sleeps the Mac as usual."
        case .noAgentWorking: "No agent is working right now."
        case .autoPausedUntilWake: "Auto mode is paused until you wake the screen."
        case .customDurationExamples: "45m, 2h, 1h30m"
        case .customDurationPrompt: "Minutes, or 90s / 45m / 2h / 1h30m — e.g. 45m for a video, 2h for a download."
        case .customDurationHelp: "Set a custom duration (e.g. 45m for YouTube, 2h for downloads)"
        case .sleepNowHelp: "Releases everything and sleeps the Mac. The Apple-menu Sleep item can't while NonSleep holds it awake."
        case .releaseHelp: "A running `nonsleep run/wait/auto` takes its lease back on its next tick."
        case .ompBuiltIn: "Built in: detected through its \"omp agent session\" power assertion"
        case .hooksIn(let path): "Hooks in \(path)"
        case .hooksExplanation(let minutes):
            "Hooks hold the Mac awake during each turn and release it when the turn ends, or \(minutes) min after the agent's last activity. Other hooks in those files are left untouched; the first edit keeps a .nonsleep-backup copy."

        case .settingAuto: "Keep awake while agents work (Auto)"
        case .settingLockOnLidClose: "Lock the screen when the lid closes"
        case .settingLockOnLidCloseHelp: "Turns display off on lid close so macOS immediately locks your session."
        case .settingSleepWhenDone: "Sleep as soon as work is done, if the lid is closed"
        case .settingSleepWhenDoneHelp: "When turns, scripts, or timers finish, automatically sleep if lid is closed."
        case .settingMinBattery(let percent): "Pause on battery below \(percent)%"
        case .settingMinBatteryHelp: "Safeguard: prevents running your battery down to zero in a backpack."
        case .settingGrace(let duration): "Keep holding \(duration) after agents finish"
        case .settingGraceHelp: "Prevents sleep-wake thrashing between consecutive agent prompt turns."
        case .settingAssertions: "Power assertions"
        case .settingAssertionsPrompt: "e.g. omp agent session, caffeinate"
        case .settingProcesses: "Processes"
        case .settingProcessesPrompt: "e.g. claude, codex, Orca"
        case .settingProcessesHelp: "Keep awake while any listed process is running (e.g. codex, brew, rsync)."
        case .settingLaunchAtLogin: "Launch at login"
        case .settingSound: "Play a sound when work finishes"
        case .settingSoundHelp: "Chimes when the last task ends, so you know from across the room. Set soundPath in config.json for your own file."
        case .settingBackpack: "Backpack protection"
        case .settingBackpackHelp: "With the lid closed on battery and no external display, release earlier when the Mac heats up — a closed Mac in a bag has no airflow."
        case .settingLanguage: "Language"

        case .setupSudoers: "Passwordless pmset rule"
        case .setupReaper: "Reaper LaunchAgent"
        case .setupReaperDetail: "Clears crashed or expired leases every minute"
        case .setupScreenLock(let delay): "Screen lock delay: \(delay)"
        case .setupScreenLockDetail: "Locking on lid close needs System Settings › Lock Screen › Require password: Immediately"
        case .setupAdminPrompt: "One administrator password, once: lets NonSleep toggle `pmset disablesleep` and clean up after crashes."
        case .setupOfflineNote: "NonSleep is 100% offline (zero network access, no telemetry, no root daemon). The sudoers rule allows only `pmset -a disablesleep 0|1`."
        }
    }

    private var vietnamese: String {
        switch self {
        case .statusStarting: "Đang khởi động…"
        case .statusPaused(let why): "Tạm dừng: \(why)"
        case .statusOtherTool: "Một ứng dụng khác đang chặn ngủ"
        case .statusAwake: "Vẫn chạy khi gập nắp máy"
        case .statusNormal: "Ngủ bình thường"
        case .blockerBattery(let percent, let minimum): "pin \(percent)% < \(minimum)%"
        case .blockerThermal(let state): "nhiệt độ mức \(state)"
        case .blockerBackpack(let state): "bảo vệ trong balo: nhiệt độ mức \(state) khi gập nắp và dùng pin"
        case .manualUntil(let time): "Thủ công đến \(time)"
        case .manualUntilOff: "Thủ công đến khi tắt"

        case .lidClosed: "Đã gập nắp"
        case .lidOpen: "Đang mở nắp"
        case .onBattery: "Dùng pin"
        case .onAC: "Cắm sạc"
        case .externalDisplay: "Có màn hình ngoài"
        case .thermalState(let state): "Nhiệt độ \(state)"

        case .keepAwake: "Giữ máy thức"
        case .forOneHour: "Trong 1 giờ"
        case .forThreeHours: "Trong 3 giờ"
        case .forEightHours: "Trong 8 giờ"
        case .untilTurnedOff: "Đến khi tự tắt"
        case .customDuration: "Thời lượng tuỳ chọn…"
        case .turnOff: "Tắt"
        case .sleepNow: "Ngủ ngay"
        case .setTimer: "Đặt hẹn giờ"
        case .cancel: "Huỷ"
        case .release: "Nhả"
        case .openNonSleep: "Mở NonSleep…"
        case .quitNonSleep: "Thoát NonSleep"
        case .autoWhileAgentsWork: "Tự động: khi agent đang làm việc"
        case .agentsLabel: "Agent"

        case .finishSetup: "Hoàn tất cài đặt…"
        case .openConfigFile: "Mở config.json"
        case .securityPolicy: "Chính sách bảo mật"

        case .sectionKeepingAwake: "Đang giữ máy thức"
        case .sectionAgents: "Agent"
        case .sectionIntegrations: "Tích hợp"
        case .sectionSettings: "Cài đặt"
        case .sectionSetup: "Thiết lập hệ thống"

        case .noLeases: "Không có gì. Gập nắp thì máy ngủ như bình thường."
        case .noAgentWorking: "Hiện không có agent nào đang chạy."
        case .autoPausedUntilWake: "Chế độ tự động tạm dừng cho đến khi bạn bật lại màn hình."
        case .customDurationExamples: "45m, 2h, 1h30m"
        case .customDurationPrompt: "Nhập số phút, hoặc 90s / 45m / 2h / 1h30m — ví dụ 45m để xem video, 2h để tải file."
        case .customDurationHelp: "Đặt thời lượng tuỳ ý (ví dụ 45m để xem YouTube, 2h để tải file)"
        case .sleepNowHelp: "Nhả toàn bộ và cho máy ngủ ngay. Nút Sleep trên menu Apple không làm được việc này khi NonSleep đang giữ máy thức."
        case .releaseHelp: "Tiến trình `nonsleep run/wait/auto` đang chạy sẽ giành lại lease ở nhịp kiểm tra kế tiếp."
        case .ompBuiltIn: "Tích hợp sẵn: nhận diện qua power assertion \"omp agent session\""
        case .hooksIn(let path): "Hook nằm ở \(path)"
        case .hooksExplanation(let minutes):
            "Hook giữ máy thức trong mỗi lượt và nhả ra khi lượt kết thúc, hoặc \(minutes) phút sau hoạt động cuối của agent. Các hook khác trong file được giữ nguyên; lần sửa đầu tiên luôn lưu một bản sao .nonsleep-backup."

        case .settingAuto: "Giữ máy thức khi agent làm việc (Tự động)"
        case .settingLockOnLidClose: "Khoá màn hình khi gập nắp"
        case .settingLockOnLidCloseHelp: "Tắt màn hình khi gập nắp để macOS khoá phiên làm việc ngay lập tức."
        case .settingSleepWhenDone: "Ngủ ngay khi xong việc, nếu nắp máy đang gập"
        case .settingSleepWhenDoneHelp: "Khi lượt chạy, script hoặc hẹn giờ kết thúc, tự động cho máy ngủ nếu nắp đang gập."
        case .settingMinBattery(let percent): "Tạm dừng khi pin dưới \(percent)%"
        case .settingMinBatteryHelp: "Van an toàn: tránh để máy cạn sạch pin trong balo."
        case .settingGrace(let duration): "Giữ thêm \(duration) sau khi agent xong việc"
        case .settingGraceHelp: "Tránh việc máy ngủ–thức liên tục giữa hai lượt chạy nối tiếp nhau."
        case .settingAssertions: "Power assertion"
        case .settingAssertionsPrompt: "ví dụ omp agent session, caffeinate"
        case .settingProcesses: "Tiến trình"
        case .settingProcessesPrompt: "ví dụ claude, codex, Orca"
        case .settingProcessesHelp: "Giữ máy thức khi bất kỳ tiến trình nào trong danh sách đang chạy (ví dụ codex, brew, rsync)."
        case .settingLaunchAtLogin: "Khởi động cùng hệ thống"
        case .settingSound: "Phát âm thanh khi xong việc"
        case .settingSoundHelp: "Kêu một tiếng khi tác vụ cuối kết thúc, để bạn biết dù đang ở xa máy. Đặt soundPath trong config.json nếu muốn dùng file riêng."
        case .settingBackpack: "Bảo vệ khi để trong balo"
        case .settingBackpackHelp: "Khi gập nắp, dùng pin và không có màn hình ngoài, máy sẽ nhả sớm hơn lúc nóng lên — máy gập trong túi không có đường thoát nhiệt."
        case .settingLanguage: "Ngôn ngữ"

        case .setupSudoers: "Quy tắc pmset không cần mật khẩu"
        case .setupReaper: "Tiến trình dọn dẹp (LaunchAgent)"
        case .setupReaperDetail: "Dọn các lease bị treo hoặc hết hạn mỗi phút"
        case .setupScreenLock(let delay): "Độ trễ khoá màn hình: \(delay)"
        case .setupScreenLockDetail: "Muốn khoá khi gập nắp, cần đặt Cài đặt hệ thống › Màn hình khoá › Yêu cầu mật khẩu: Ngay lập tức"
        case .setupAdminPrompt: "Chỉ cần nhập mật khẩu quản trị một lần duy nhất: để NonSleep bật/tắt `pmset disablesleep` và tự dọn dẹp sau khi gặp sự cố."
        case .setupOfflineNote: "NonSleep hoạt động 100% ngoại tuyến (không truy cập mạng, không telemetry, không daemon chạy quyền root). Quy tắc sudoers chỉ cho phép đúng `pmset -a disablesleep 0|1`."
        }
    }
}
