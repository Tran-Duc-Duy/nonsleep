import Foundation

/// One finished lid-closed session. Fields are deliberately small and fixed-width: the whole
/// point of this file is a bounded on-disk footprint, so nothing here may grow with usage.
public struct SessionRecord: Codable, Sendable, Identifiable, Equatable {
    /// Longest `reason` kept on disk. Agents (and MCP callers) can pass arbitrary text, so it is
    /// truncated before it ever reaches the file.
    public static let maxReasonLength = 80

    public var startedAt: Date
    public var endedAt: Date
    public var reason: String
    public var startBatteryPercent: Int?
    public var endBatteryPercent: Int?
    public var peakThermalState: String

    /// Start instant identifies a session: sessions never overlap, so no UUID is stored.
    public var id: Date { startedAt }

    public var duration: TimeInterval { max(0, endedAt.timeIntervalSince(startedAt)) }

    public init(
        startedAt: Date,
        endedAt: Date,
        reason: String,
        startBatteryPercent: Int? = nil,
        endBatteryPercent: Int? = nil,
        peakThermalState: String = "nominal"
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.reason = Self.truncate(reason)
        self.startBatteryPercent = startBatteryPercent
        self.endBatteryPercent = endBatteryPercent
        self.peakThermalState = peakThermalState
    }

    /// Clamps to `maxReasonLength` characters, marking the cut so a trimmed reason is obvious.
    static func truncate(_ reason: String) -> String {
        let collapsed = reason.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard collapsed.count > maxReasonLength else { return collapsed }
        return String(collapsed.prefix(maxReasonLength - 1)) + "…"
    }
}

/// Append-only ring of recent sessions in a single JSON file, bounded three ways: by entry count,
/// by age, and by a hard byte ceiling on the file itself. A corrupt or oversized file is dropped
/// rather than parsed, so history can never cost more than `maxFileBytes` of disk or memory.
public struct HistoryStore: Sendable {
    /// Refuse to read (and reset) anything larger. 50 records × ~200 B ≈ 10 KB, so 64 KiB is
    /// slack for a tampered or interrupted write, not a target.
    public static let maxFileBytes = 64 * 1024
    /// Sessions shorter than this are churn (a reconcile that flipped the flag twice), not work.
    public static let minimumDuration: TimeInterval = 5

    public let fileURL: URL
    public let maxEntries: Int
    public let retentionDays: Int

    public init(fileURL: URL, maxEntries: Int = 50, retentionDays: Int = 30) {
        self.fileURL = fileURL
        self.maxEntries = max(0, maxEntries)
        self.retentionDays = max(0, retentionDays)
    }

    public static func standard(store: Store, config: Config = .defaults) -> HistoryStore {
        HistoryStore(
            fileURL: store.directory.appendingPathComponent("history.json"),
            maxEntries: config.historyMaxEntries,
            retentionDays: config.historyRetentionDays
        )
    }

    /// Bytes currently on disk (0 when there is no history yet).
    public var fileSize: Int {
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return (attributes?[.size] as? NSNumber)?.intValue ?? 0
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        // Compact, not pretty: this file is read through `nonsleep history`, never by hand.
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Newest first. Never reads a file over `maxFileBytes`: an oversized one is deleted, because
    /// losing old statistics beats loading unbounded data a crash or another tool left behind.
    public func load(now: Date = Date()) -> [SessionRecord] {
        let size = fileSize
        guard size > 0 else { return [] }
        guard size <= Self.maxFileBytes else {
            try? FileManager.default.removeItem(at: fileURL)
            return []
        }
        guard let data = try? Data(contentsOf: fileURL),
              let records = try? Self.decoder().decode([SessionRecord].self, from: data)
        else { return [] }
        return prune(records, now: now)
    }

    /// Applies both bounds: drops anything past the retention window, then keeps the newest
    /// `maxEntries`. `retentionDays == 0` disables ageing; `maxEntries == 0` disables history.
    func prune(_ records: [SessionRecord], now: Date) -> [SessionRecord] {
        guard maxEntries > 0 else { return [] }
        var kept = records.sorted { $0.startedAt > $1.startedAt }
        if retentionDays > 0 {
            let cutoff = now.addingTimeInterval(-Double(retentionDays) * 86_400)
            kept.removeAll { $0.startedAt < cutoff }
        }
        if kept.count > maxEntries { kept = Array(kept.prefix(maxEntries)) }
        return kept
    }

    public func save(_ records: [SessionRecord], now: Date = Date()) throws {
        let kept = prune(records, now: now)
        guard !kept.isEmpty else {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Self.encoder().encode(kept).write(to: fileURL, options: .atomic)
    }

    /// Records one session unless history is off or the session was too short to be work.
    /// - Returns: `true` when a record was written.
    @discardableResult
    public func record(
        startedAt: Date,
        endedAt: Date,
        reason: String,
        startBattery: Int?,
        endBattery: Int?,
        peakThermal: String,
        now: Date = Date()
    ) throws -> Bool {
        guard maxEntries > 0 else { return false }
        let entry = SessionRecord(
            startedAt: startedAt,
            endedAt: endedAt,
            reason: reason,
            startBatteryPercent: startBattery,
            endBatteryPercent: endBattery,
            peakThermalState: peakThermal
        )
        guard entry.duration >= Self.minimumDuration else { return false }
        var existing = load(now: now)
        existing.insert(entry, at: 0)
        try save(existing, now: now)
        return true
    }

    // MARK: In-progress session

    /// The session currently being held, as one fixed-size record beside the history file.
    /// It survives the process that opened it, so the reaper can close a session the menu bar
    /// app or a CLI run started.
    var markerURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("current-session.json")
    }

    /// Opens a session, unless one is already open: if the flag is re-applied because something
    /// outside NonSleep cleared it, the session continues, keeping its original start and peak
    /// rather than restarting the clock.
    public func openSession(at start: Date, reason: String, battery: Int?, thermal: Thermal) {
        guard maxEntries > 0, openMarker() == nil else { return }
        let marker = SessionRecord(
            startedAt: start, endedAt: start, reason: reason,
            startBatteryPercent: battery, endBatteryPercent: battery,
            peakThermalState: thermal.rawValue
        )
        try? FileManager.default.createDirectory(
            at: markerURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? Self.encoder().encode(marker).write(to: markerURL, options: .atomic)
    }

    /// Raises the session's recorded peak when the machine gets hotter. Called on every
    /// reconcile while the flag is held, so "peak" means the hottest point of the session,
    /// not whatever it happened to be at the end.
    public func observe(thermal: Thermal) {
        guard var marker = openMarker(), Thermal(rawValue: marker.peakThermalState) ?? .nominal < thermal
        else { return }
        marker.peakThermalState = thermal.rawValue
        try? Self.encoder().encode(marker).write(to: markerURL, options: .atomic)
    }

    /// Closes the open session and appends it. No marker (history off, or a session opened
    /// before history existed) means nothing to record.
    /// - Returns: `true` when a record was written.
    @discardableResult
    public func closeSession(at end: Date, battery: Int?, thermal: Thermal) -> Bool {
        guard let marker = openMarker() else { return false }
        try? FileManager.default.removeItem(at: markerURL)
        let peak = max(Thermal(rawValue: marker.peakThermalState) ?? .nominal, thermal)
        return (try? record(
            startedAt: marker.startedAt, endedAt: end, reason: marker.reason,
            startBattery: marker.startBatteryPercent, endBattery: battery,
            peakThermal: peak.rawValue, now: end
        )) ?? false
    }

    func openMarker() -> SessionRecord? {
        guard let data = try? Data(contentsOf: markerURL) else { return nil }
        return try? Self.decoder().decode(SessionRecord.self, from: data)
    }

    /// Drops recorded sessions and any session still open, so `history` is empty afterwards.
    public func clear() throws {
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: markerURL)
    }
}
