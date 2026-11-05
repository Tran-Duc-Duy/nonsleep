import Foundation

/// What `nonsleep status --json` prints: the whole of `nonsleep status` with stable keys, so a
/// tray indicator, a GNOME extension, a waybar module or a shell script never has to parse the
/// human-readable output (which is localized and free to change).
///
/// `schema` is the contract: fields may be added without bumping it, renamed or removed only with
/// a bump. Enumerated values (`mode`, `platform`, `power.thermal`, `agents[].source`) are stable
/// English identifiers; `headline` and `blockedBy` are localized prose meant for display only.
public struct StatusReport: Codable, Sendable, Equatable {
    public static let schema = 1

    /// Mirrors `Status.headline`, in the same precedence order.
    public enum Mode: String, Codable, Sendable {
        /// Lid-closed mode is on and held by NonSleep.
        case awake
        /// No live lease: the machine sleeps as usual.
        case normal
        /// Leases are live but a safety cut-out (battery, heat) overrides them; see `blockedBy`.
        case suspended
        /// Sleep is disabled, but by something else (Amphetamine, a manual `pmset`, another lock).
        case foreign
    }

    public struct Power: Codable, Sendable, Equatable {
        /// macOS: `pmset disablesleep`. Linux: a `handle-lid-switch:sleep` inhibitor is held.
        public var sleepDisabled: Bool
        public var lidClosed: Bool
        public var externalDisplay: Bool
        public var onBattery: Bool
        /// `nil` on machines without a battery.
        public var batteryPercent: Int?
        /// Always `nominal` on Linux: there is no thermal cut-out there.
        public var thermal: Thermal
    }

    public struct LeaseInfo: Codable, Sendable, Equatable {
        public var id: String
        public var reason: String
        /// `nil` for detached leases (`nonsleep on 3h`), which outlive the process that made them.
        public var ownerPID: Int32?
        /// `nil` when the lease lives until `off` or reboot.
        public var expiresAt: Date?
    }

    /// Heat bookkeeping for the current episode (macOS only; idle everywhere else).
    public struct ThermalGuardInfo: Codable, Sendable, Equatable {
        public var trips: Int
        public var resumes: Int
        public var retryLimit: Int
        public var lockedOut: Bool
    }

    public var schema: Int
    public var version: String
    /// `macos` or `linux`: the two platforms behave differently enough that frontends branch on it.
    public var platform: String
    public var generatedAt: Date
    public var mode: Mode
    /// Localized one-liner, the same text `nonsleep status` prints first.
    public var headline: String
    /// Localized reason the live leases are not honored right now; `nil` unless `mode` is `suspended`.
    public var blockedBy: String?
    public var power: Power
    public var leases: [LeaseInfo]
    public var agents: [AgentActivity]
    public var thermalGuard: ThermalGuardInfo

    public init(_ status: Status, agents: [AgentActivity], thermalRetryLimit: Int, now: Date = Date()) {
        schema = Self.schema
        version = NonSleepVersion.current
        #if os(macOS)
        platform = "macos"
        #else
        platform = "linux"
        #endif
        generatedAt = now
        if status.blockedBy != nil {
            mode = .suspended
        } else if status.setByOtherTool {
            mode = .foreign
        } else {
            mode = status.power.sleepDisabled ? .awake : .normal
        }
        headline = status.headline
        blockedBy = status.blockedBy
        power = Power(
            sleepDisabled: status.power.sleepDisabled,
            lidClosed: status.power.lidClosed,
            externalDisplay: status.power.externalDisplay,
            onBattery: status.power.onBattery,
            batteryPercent: status.power.batteryPercent,
            thermal: status.power.thermal
        )
        leases = status.leases.map {
            LeaseInfo(id: $0.id, reason: $0.reason, ownerPID: $0.ownerPID.map { Int32($0) }, expiresAt: $0.expiresAt)
        }
        self.agents = agents
        thermalGuard = ThermalGuardInfo(
            trips: status.thermalGuard.trips,
            resumes: status.thermalGuard.resumes,
            retryLimit: thermalRetryLimit,
            lockedOut: status.thermalGuard.lockedOut
        )
    }

    /// Pretty-printed with sorted keys and ISO-8601 dates, like `nonsleep config`.
    public func json() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return String(decoding: (try? encoder.encode(self)) ?? Data(), as: UTF8.self)
    }

    /// Counterpart of `json()`, for frontends and tests written in Swift.
    public static func decode(_ json: String) throws -> StatusReport {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StatusReport.self, from: Data(json.utf8))
    }
}
