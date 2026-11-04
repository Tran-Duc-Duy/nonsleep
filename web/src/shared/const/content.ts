export type Language = "en" | "vi";

export interface FeatureContent {
  id: string;
  badge: string;
  title: string;
  tagline: string;
  description: string;
  humanNote: string;
  iconName: "Laptop" | "Bot" | "HeartPulse" | "Lock" | "ShieldCheck" | "Timer";
}

export interface FaqContent {
  id: string;
  question: string;
  answer: string;
  category: string;
}

export const DICTIONARY = {
  en: {
    nav: {
      features: "Features",
      howItWorks: "How It Works",
      agents: "Agents",
      compare: "Compare",
      benchmarks: "Benchmarks",
      faq: "FAQ",
      download: "Download Free",
      star: "Star on GitHub",
    },
    hero: {
      pill: "v0.3.0: MCP server, diagnostics & session history",
      titleLine1: "Send the prompt. Shut the lid.",
      titleLine2: "Walk away.",
      subtitle:
        "You shouldn't have to babysit an open laptop just so Claude, Cursor, or Codex can finish a 30-minute turn. NonSleep keeps your Mac working with the lid closed — and puts it to sleep the second your agent finishes.",
      downloadCta: "Download for macOS (Universal)",
      downloadSub: "Universal binary for M1–M4 Apple Silicon & Intel · Free & Open Source",
      githubCta: "View on GitHub",
      quickCopy: "One-line installation:",
      badgeOffline: "No Telemetry (No Background Network)",
      badgeNative: "Native Swift (2.5 MB)",
      badgeSafe: "No Root Daemon",
      badgeLock: "Locks Screen on Close",
    },
    mockup: {
      title: "Interactive Clamshell Simulator",
      subtitle: "Click to test how NonSleep handles an agent turn when you shut your laptop:",
      btnTurnStart: "1. Prompt In Flight (Lid Open)",
      btnCloseLid: "2. Shut MacBook Lid",
      btnTurnDone: "3. Agent Finishes Task",
      stateOpen: "MacBook Open · Claude Code running turn...",
      stateClosedWorking: "Lid Closed · NonSleep holding lease · Screen Locked",
      stateClosedSleeping: "Turn Finished · Lease Released · Mac Sleeping (Zzz)",
      statLease: "Managed Lease:",
      statScreen: "Screen Security:",
      statBattery: "Battery Cut-out:",
    },
    painRelief: {
      badge: "The Real Developer Pain",
      title: "Sound Familiar?",
      subtitle: "We built NonSleep because we were tired of losing hours of coding progress.",
      beforeTitle: "Without NonSleep (The 11 PM Nightmare)",
      beforePoints: [
        "You give Claude Code or Cursor a 30-minute refactoring prompt before going to bed.",
        "You shut the lid and head to sleep. macOS immediately puts the laptop to sleep.",
        "Your agent freezes after step 2. The other 18 steps never run.",
        "You wake up at 7 AM to find zero progress, wasted time, and broken deadlines.",
      ],
      afterTitle: "With NonSleep (The Seamless Morning)",
      afterPoints: [
        "You submit the prompt and shut the lid immediately.",
        "NonSleep keeps the task cawing with the screen locked tight.",
        "At step 20, Claude finishes. NonSleep detects the Stop event and puts the Mac to sleep safely.",
        "You wake up to a cool laptop, full battery, and completed, tested code.",
      ],
    },
    featuresHeading: {
      badge: "Engineered for AI",
      title: "Why Traditional Tools Fail You",
      subtitle: "Apple designed caffeinate to stop your display from dimming while you stare at it. NonSleep is designed for when you close the lid and walk away.",
    },
    features: [
      {
        id: "clamshell-fix",
        badge: "The Core Fix",
        title: "True Clamshell Without a Monitor",
        tagline: "Apple kills closed-lid tasks. NonSleep doesn't let it.",
        description:
          "Standard tools only block idle sleep. The moment you close the lid without an external monitor, macOS forces sleep. NonSleep controls the only system switch that survives a shut lid: pmset disablesleep 1.",
        humanNote: "No dummy HDMI plugs. No bulky monitors. Just close your laptop.",
        iconName: "Laptop",
      },
      {
        id: "agent-aware",
        badge: "Zero Babysitting",
        title: "Agent-Aware: Sleep When Done",
        tagline: "Never guess when a turn finishes.",
        description:
          "Connects directly to Claude Code, Cursor, Codex, and omp hooks. While your agent thinks or executes commands, your Mac stays awake. The millisecond it finishes, NonSleep releases the flag so your Mac sleeps.",
        humanNote: "No more running for 3 hours when the agent was done in 10 minutes.",
        iconName: "Bot",
      },
      {
        id: "backpack-safe",
        badge: "Hardware Protection",
        title: "Won't Bake in Your Backpack",
        tagline: "Automatic thermal & battery cut-outs.",
        description:
          "Opening your backpack to find a scalding hot MacBook with 1% battery is a nightmare. NonSleep continuously watches temperature and battery sensors. If it gets hot or battery drops below 20%, it halts immediately.",
        humanNote: "Safety first: your Mac always sleeps before battery drains to zero.",
        iconName: "ShieldCheck",
      },
      {
        id: "auto-lock",
        badge: "Privacy Guarantee",
        title: "Shut Lid = Instant Screen Lock",
        tagline: "Keeps running, but locks down your screen.",
        description:
          "Your code keeps compiling, but your session is safe. The moment the clamshell closes, NonSleep turns off the display, prompting macOS to lock the session immediately with Touch ID or password.",
        humanNote: "If someone opens your laptop at a coffee shop, it's locked tight.",
        iconName: "Lock",
      },
      {
        id: "reaper-engine",
        badge: "No Stuck Flags",
        title: "Crash-Proof Leases & Reaper",
        tagline: "Never leaves your Mac permanently awake.",
        description:
          "Ever run pmset manually and forgotten to turn it off? Your battery died overnight. NonSleep ties every request to a process lease. If your agent crashes or gets kill -9, our background reaper cleans it in 60s.",
        humanNote: "No forgotten background flags. Normal sleep is always guaranteed.",
        iconName: "HeartPulse",
      },
      {
        id: "youtube-timer",
        badge: "Lifestyle Feature",
        title: "Bedtime Podcast & YouTube Timer",
        tagline: "Fall asleep to audio with the lid closed.",
        description:
          "Want to fall asleep listening to a YouTube video or podcast? Click Custom in the menu bar, type 45m, and shut the lid. Audio plays through speakers or AirPods; your Mac sleeps at 45 minutes.",
        humanNote: "Works with any duration: 30m, 45m, 2h, 1h30m.",
        iconName: "Timer",
      },
    ] as FeatureContent[],
    benchmarksHeading: {
      badge: "Pure Swift",
      title: "Real Measurements on Apple Silicon",
      subtitle: "No Electron bloat. Starts in 30ms, takes ~25 MB RAM, and uses 0.0% CPU when idle.",
    },
    securityHeading: {
      badge: "Audit-Ready",
      title: "No Telemetry. We Don't Want Your Code.",
      subtitle: "Nothing is sent on its own: no analytics, no crash reports, no launch check. Zero third-party dependencies, and the only request is the update button you press.",
    },
    faqHeading: {
      badge: "Clear Answers",
      title: "Frequently Asked Questions",
      subtitle: "Everything you need to know about safety, permissions, and everyday workflows.",
    },
  },
  vi: {
    nav: {
      features: "Tính năng",
      howItWorks: "Cách hoạt động",
      agents: "Hỗ trợ Agent",
      compare: "So sánh",
      benchmarks: "Hiệu năng",
      faq: "Hỏi đáp",
      download: "Tải miễn phí",
      star: "Tặng Star",
    },
    hero: {
      pill: "Bản v0.3.0: MCP server, chẩn đoán & lịch sử phiên",
      titleLine1: "Gõ prompt. Gập máy lại.",
      titleLine2: "Đi làm việc khác.",
      subtitle:
        "Bạn không cần phải ngồi trông cái màn hình laptop chỉ để chờ Claude Code, Cursor hay Codex chạy xong một turn 30 phút. NonSleep giữ Mac tiếp tục cày khi gập nắp — và tự cho máy ngủ ngay giây phút agent xong việc.",
      downloadCta: "Tải cho macOS (Universal)",
      downloadSub: "Bản universal mượt mà cho M1–M4 Apple Silicon & Intel · Mã nguồn mở & Miễn phí",
      githubCta: "Xem trên GitHub",
      quickCopy: "Cài đặt nhanh bằng 1 dòng lệnh:",
      badgeOffline: "Không telemetry (không chạy nền ra mạng)",
      badgeNative: "Native Swift (2.5 MB)",
      badgeSafe: "Không chạy Root Daemon",
      badgeLock: "Gập máy tự khóa màn hình",
    },
    mockup: {
      title: "Mô phỏng Gập Máy Thực Tế",
      subtitle: "Bấm các nút dưới đây để xem NonSleep xử lý vòng đời khi bạn gập laptop:",
      btnTurnStart: "1. Prompt đang chạy (Mở máy)",
      btnCloseLid: "2. Gập nắp MacBook lại",
      btnTurnDone: "3. Agent hoàn thành task",
      stateOpen: "MacBook đang mở · Claude Code đang suy nghĩ & sửa file...",
      stateClosedWorking: "Đã gập nắp · NonSleep giữ máy cày tiếp · Màn hình tự khóa",
      stateClosedSleeping: "Agent xong việc · Tự nhả cờ · Mac đi ngủ an toàn (Zzz)",
      statLease: "Trạng thái Lease:",
      statScreen: "Bảo mật màn hình:",
      statBattery: "Cắt pin an toàn:",
    },
    painRelief: {
      badge: "Nỗi Đau Lập Trình Viên",
      title: "Bạn Có Thấy Quen Không?",
      subtitle: "NonSleep ra đời vì tụi mình quá mệt mỏi với việc mất trắng tiến độ cày đêm của Agent.",
      beforeTitle: "Khi Chưa Có NonSleep (Cơn ác mộng 11 giờ đêm)",
      beforePoints: [
        "Bạn giao cho Claude Code hoặc Cursor một prompt refactor 30 phút trước khi đi ngủ.",
        "Bạn gập máy lại đi ngủ. Vừa gập nắp xuống là macOS lập tức ép máy đi ngủ theo.",
        "Agent đứng hình ngay bước thứ 2. 18 bước còn lại nằm bất động suốt đêm.",
        "7 giờ sáng thức dậy mở máy ra: task chưa xong, công việc trễ deadline, phí nguyên một đêm.",
      ],
      afterTitle: "Khi Có NonSleep (Thức dậy là code xong)",
      afterPoints: [
        "Bạn gõ prompt xong là gập máy lại ngay, bỏ lên bàn hoặc nhét balo đi về.",
        "NonSleep giữ máy cày tiếp, nhưng màn hình tự khóa ngay để chống người khác mở xem lén.",
        "Tới bước 20, Claude xong việc. NonSleep bắt tín hiệu Stop và cho Mac ngủ ngay lập tức.",
        "Sáng dậy: máy mát rượi, pin không cạn kiệt, code đã chạy xong và test xanh lét.",
      ],
    },
    featuresHeading: {
      badge: "Thiết kế cho AI",
      title: "Tại Sao Các Tool Khác Khiến Bạn Thất Vọng?",
      subtitle: "Apple tạo ra caffeinate chỉ để màn hình không bị mờ khi bạn ngồi nhìn vào nó. NonSleep sinh ra để bạn gập máy lại và an tâm đi làm việc khác.",
    },
    features: [
      {
        id: "clamshell-fix",
        badge: "Giải pháp cốt lõi",
        title: "Gập Máy Vẫn Cày (Không Cần Cắm Màn Rời)",
        tagline: "Apple ép gập máy là phải ngủ. NonSleep thì không.",
        description:
          "Caffeinate hay Amphetamine chỉ chặn ngủ khi mở máy. Gập nắp máy lại là macOS ngắt hết task. NonSleep điều khiển cờ hệ thống duy nhất sống sót khi gập máy: pmset disablesleep 1.",
        humanNote: "Không cần cắm màn hình rời. Không cần cắm sạc. Cứ gập máy là chạy.",
        iconName: "Laptop",
      },
      {
        id: "agent-aware",
        badge: "Không Cần Canh Chừng",
        title: "Agent Xong Là Tự Ngủ Ngay",
        tagline: "Không cần đoán mò hẹn giờ 3 tiếng.",
        description:
          "NonSleep gắn trực tiếp vào hook của Claude Code, Cursor, Codex và omp. Khi agent đang suy nghĩ hay gọi tool, máy thức. Đúng một mili-giây khi agent kết thúc câu trả lời, NonSleep tự cho Mac đi ngủ.",
        humanNote: "Không bao giờ có chuyện agent chạy 10 phút xong mà máy thức ngu ngơ thêm 3 tiếng.",
        iconName: "Bot",
      },
      {
        id: "backpack-safe",
        badge: "Bảo Vệ Phần Cứng",
        title: "Không Lo Nóng Máy Trong Balo",
        tagline: "Tự ngắt khi máy nóng hoặc pin dưới 20%.",
        description:
          "Cơn ác mộng mở balo ra thấy MacBook nóng ran và cạn kiệt 0% pin sẽ không bao giờ xảy ra. NonSleep theo dõi nhiệt độ và mức pin liên tục: nếu máy nóng hoặc pin < 20%, nó lập tức ngắt lệnh để máy ngủ an toàn.",
        humanNote: "An toàn là trên hết: pin không bao giờ bị xả cạn kiệt trong túi.",
        iconName: "ShieldCheck",
      },
      {
        id: "auto-lock",
        badge: "Bảo Mật Tuyệt Đối",
        title: "Gập Máy Là Khóa Màn Hình Ngay",
        tagline: "Task vẫn chạy ngầm, nhưng người ngoài không xem lén được.",
        description:
          "Mac tiếp tục compile code, nhưng phiên làm việc của bạn được khóa chặt. Ngay khi nắp máy gập xuống, NonSleep tắt màn hình để kích hoạt chế độ khóa Touch ID/Password của macOS ngay tức thì.",
        humanNote: "Ngồi quán cà phê gập máy đi lấy nước, không ai mở máy xem trộm được.",
        iconName: "Lock",
      },
      {
        id: "reaper-engine",
        badge: "Không Lo Kẹt Cờ",
        title: "Cơ Chế Lease & Reaper Chống Crash",
        tagline: "Tuyệt đối không để máy bị thức vĩnh viễn.",
        description:
          "Đã bao giờ bạn tự gõ lệnh pmset rồi quên tắt khiến máy thức trắng đêm chưa? NonSleep gắn mỗi lệnh giữ thức với một lease tạm thời. Nếu agent bị crash hay kill -9, reaper chạy ngầm sẽ tự động dọn sạch sau 60 giây.",
        humanNote: "Máy luôn được bảo đảm trả về chế độ ngủ bình thường của hệ thống.",
        iconName: "HeartPulse",
      },
      {
        id: "youtube-timer",
        badge: "Tính năng đời sống",
        title: "Hẹn Giờ Ngủ Nghe YouTube & Podcast",
        tagline: "Gập máy nghe nhạc trước khi ngủ, hết giờ tự tắt.",
        description:
          "Muốn nghe một bài giảng YouTube hay podcast trước khi ngủ? Bấm Custom trên menu bar, gõ 45m và gập máy lại. Loa vẫn phát bình thường; đúng 45 phút sau máy sẽ tự động đi ngủ.",
        humanNote: "Gõ bất kỳ thời gian nào bạn muốn: 30m, 45m, 2h, 1h30m.",
        iconName: "Timer",
      },
    ] as FeatureContent[],
    benchmarksHeading: {
      badge: "Thuần Swift",
      title: "Đo Đạc Hiệu Năng Thực Tế Trên Apple Silicon",
      subtitle: "Không dùng Electron. Khởi động trong 30ms, chỉ tốn ~25 MB RAM và 0.0% CPU lúc chạy nền.",
    },
    securityHeading: {
      badge: "Minh Bạch 100%",
      title: "Không Telemetry. Tụi Mình Không Cần Code Của Bạn.",
      subtitle: "Không tự gửi bất cứ thứ gì: không analytics, không crash report, không kiểm tra lúc khởi động. Không dùng thư viện ngoài, và request duy nhất là nút kiểm tra bản mới do bạn bấm.",
    },
    faqHeading: {
      badge: "Giải Đáp Thắc Mắc",
      title: "Những Câu Hỏi Thường Gặp",
      subtitle: "Tất cả những gì bạn cần biết về độ an toàn, quyền hạn và cách dùng hàng ngày.",
    },
  },
};
