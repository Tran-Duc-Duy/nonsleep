import Foundation

public enum Thermal: String, Sendable, Comparable {
    case nominal, fair, serious, critical

    private var rank: Int {
        switch self {
        case .nominal: 0
        case .fair: 1
        case .serious: 2
        case .critical: 3
        }
    }

    public static func < (lhs: Thermal, rhs: Thermal) -> Bool { lhs.rank < rhs.rank }
}

/// Everything NonSleep needs to know about the machine at one instant.
public struct PowerSnapshot: Sendable, Equatable {
    /// `pmset disablesleep` flag: when set, closing the lid does not sleep the Mac.
    public var sleepDisabled: Bool
    public var lidClosed: Bool
    public var externalDisplay: Bool
    public var onBattery: Bool
    /// `nil` on Macs without a battery.
    public var batteryPercent: Int?
    public var thermal: Thermal

    public init(
        sleepDisabled: Bool = false, lidClosed: Bool = false, externalDisplay: Bool = false,
        onBattery: Bool = false, batteryPercent: Int? = nil, thermal: Thermal = .nominal
    ) {
        self.sleepDisabled = sleepDisabled
        self.lidClosed = lidClosed
        self.externalDisplay = externalDisplay
        self.onBattery = onBattery
        self.batteryPercent = batteryPercent
        self.thermal = thermal
    }
}

public protocol PowerControl: Sendable {
    func snapshot() -> PowerSnapshot
    func setSleepDisabled(_ disabled: Bool) throws
    func sleepNow()
}

public enum NonSleepError: Error, CustomStringConvertible {
    case pmsetFailed(String)
    case setupFailed(String)
    case inhibitFailed(String)
    case invalidConfig(URL, String)
    case invalidDuration(String)
    case unknownAgent(String)

    public var description: String {
        switch self {
        case .pmsetFailed(let detail):
            "pmset failed (\(detail)). Finish setup in the NonSleep window, or run `nonsleep setup`, to allow `sudo -n pmset -a disablesleep 0|1`."
        case .setupFailed(let detail):
            "setup failed: \(detail)"
        case .inhibitFailed(let detail):
            "systemd-inhibit failed (\(detail)). NonSleep needs systemd-logind and a local, active session (not SSH)."
        case .invalidConfig(let url, let detail):
            "invalid config \(url.path): \(detail)"
        case .invalidDuration(let text):
            "invalid duration \"\(text)\" (examples: 90m, 3h, 1h30m)"
        case .unknownAgent(let name):
            "unknown agent \"\(name)\" (claude, cursor, antigravity, all)"
        }
    }
}

