import Foundation

/// `~/Library/Application Support/NonSleep/config.json`. Every key is optional.
public struct Config: Codable, Sendable, Equatable {
    /// Power-assertion names (case-insensitive substring) that mean "an agent is working".
    /// omp holds "omp agent session" only while a prompt is in flight; `caffeinate -i <cmd>`
    /// holds "caffeinate command-line tool" for the lifetime of `<cmd>`.
    public var assertionNames: [String]
    /// Executable or script names (e.g. "claude") whose mere presence means "an agent is working".
    public var processNames: [String]
    /// On battery below this percentage, lid-closed mode is suspended and normal sleep returns.
    public var minBatteryPercent: Int
    /// Auto mode keeps holding this long after the last agent activity (covers gaps between turns).
    public var graceSeconds: Int
    /// When lid-closed mode ends while the lid is closed (and no external display), sleep immediately.
    public var sleepWhenDone: Bool
    /// Menu bar app: when the lid closes while NonSleep keeps the Mac awake (and no external
    /// display is attached), turn the display off so macOS locks the session.
    public var lockOnLidClose: Bool
    /// Hook integrations (Claude Code, Cursor, Antigravity): a turn's lease expires this long
    /// after the agent's last hook event, covering turns that end without a stop event.
    public var hookTimeoutMinutes: Int
    /// Play an audio chime when all tasks complete and normal sleep is restored.
    public var soundEnabled: Bool
    /// Optional path to a custom sound file (.aiff, .wav, .mp3). If nil, plays macOS system chime.
    public var soundPath: String?
    /// Emergency cut-out when closed lid on battery experiences high temperatures.
    public var backpackProtection: Bool
    /// Sessions kept in `history.json`; `0` turns session history off entirely.
    public var historyMaxEntries: Int
    /// Sessions older than this are dropped on the next write; `0` keeps them until evicted by count.
    public var historyRetentionDays: Int
    /// Interface language; `auto` follows the system.
    public var language: Language

    public static let defaults = Config(
        assertionNames: ["omp agent session", "caffeinate"],
        processNames: [],
        minBatteryPercent: 20,
        graceSeconds: 120,
        sleepWhenDone: true,
        lockOnLidClose: true,
        hookTimeoutMinutes: 30,
        soundEnabled: false,
        soundPath: nil,
        backpackProtection: true,
        historyMaxEntries: 50,
        historyRetentionDays: 30,
        language: .auto
    )

    public init(
        assertionNames: [String], processNames: [String], minBatteryPercent: Int,
        graceSeconds: Int, sleepWhenDone: Bool, lockOnLidClose: Bool, hookTimeoutMinutes: Int,
        soundEnabled: Bool = false, soundPath: String? = nil, backpackProtection: Bool = true,
        historyMaxEntries: Int = 50, historyRetentionDays: Int = 30, language: Language = .auto
    ) {
        self.assertionNames = assertionNames
        self.processNames = processNames
        self.minBatteryPercent = minBatteryPercent
        self.graceSeconds = graceSeconds
        self.sleepWhenDone = sleepWhenDone
        self.lockOnLidClose = lockOnLidClose
        self.hookTimeoutMinutes = hookTimeoutMinutes
        self.soundEnabled = soundEnabled
        self.soundPath = soundPath
        self.backpackProtection = backpackProtection
        self.historyMaxEntries = historyMaxEntries
        self.historyRetentionDays = historyRetentionDays
        self.language = language
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = Config.defaults
        assertionNames = try container.decodeIfPresent([String].self, forKey: .assertionNames) ?? fallback.assertionNames
        processNames = try container.decodeIfPresent([String].self, forKey: .processNames) ?? fallback.processNames
        minBatteryPercent = try container.decodeIfPresent(Int.self, forKey: .minBatteryPercent) ?? fallback.minBatteryPercent
        graceSeconds = try container.decodeIfPresent(Int.self, forKey: .graceSeconds) ?? fallback.graceSeconds
        sleepWhenDone = try container.decodeIfPresent(Bool.self, forKey: .sleepWhenDone) ?? fallback.sleepWhenDone
        lockOnLidClose = try container.decodeIfPresent(Bool.self, forKey: .lockOnLidClose) ?? fallback.lockOnLidClose
        hookTimeoutMinutes = try container.decodeIfPresent(Int.self, forKey: .hookTimeoutMinutes) ?? fallback.hookTimeoutMinutes
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? fallback.soundEnabled
        soundPath = try container.decodeIfPresent(String.self, forKey: .soundPath) ?? fallback.soundPath
        backpackProtection = try container.decodeIfPresent(Bool.self, forKey: .backpackProtection) ?? fallback.backpackProtection
        historyMaxEntries = try container.decodeIfPresent(Int.self, forKey: .historyMaxEntries) ?? fallback.historyMaxEntries
        historyRetentionDays = try container.decodeIfPresent(Int.self, forKey: .historyRetentionDays) ?? fallback.historyRetentionDays
        // An unknown language code must not invalidate the whole config.
        language = (try? container.decodeIfPresent(Language.self, forKey: .language)) .flatMap { $0 } ?? fallback.language
    }

    public static func load(from url: URL) throws -> Config {
        guard let data = try? Data(contentsOf: url) else { return .defaults }
        do {
            return try JSONDecoder().decode(Config.self, from: data)
        } catch {
            throw NonSleepError.invalidConfig(url, String(describing: error))
        }
    }

    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json().utf8).write(to: url, options: .atomic)
    }

    public func json() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: (try? encoder.encode(self)) ?? Data(), as: UTF8.self)
    }
}
