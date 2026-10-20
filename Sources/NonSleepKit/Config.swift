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

    public static let defaults = Config(
        assertionNames: ["omp agent session", "caffeinate"],
        processNames: [],
        minBatteryPercent: 20,
        graceSeconds: 120,
        sleepWhenDone: true,
        lockOnLidClose: true,
        hookTimeoutMinutes: 30
    )

    public init(
        assertionNames: [String], processNames: [String], minBatteryPercent: Int,
        graceSeconds: Int, sleepWhenDone: Bool, lockOnLidClose: Bool, hookTimeoutMinutes: Int
    ) {
        self.assertionNames = assertionNames
        self.processNames = processNames
        self.minBatteryPercent = minBatteryPercent
        self.graceSeconds = graceSeconds
        self.sleepWhenDone = sleepWhenDone
        self.lockOnLidClose = lockOnLidClose
        self.hookTimeoutMinutes = hookTimeoutMinutes
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
