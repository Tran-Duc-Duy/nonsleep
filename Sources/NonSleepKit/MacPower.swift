#if os(macOS)
import CoreGraphics
import Foundation
import IOKit
import IOKit.ps

extension Thermal {
    init(_ state: ProcessInfo.ThermalState) {
        switch state {
        case .nominal: self = .nominal
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        @unknown default: self = .critical
        }
    }
}

/// The real machine. Toggling the flag goes through a single sudoers-whitelisted command.
public struct SystemPower: PowerControl {
    public init() {}

    public func snapshot() -> PowerSnapshot {
        let battery = Self.battery()
        return PowerSnapshot(
            sleepDisabled: Self.rootDomainFlag("SleepDisabled"),
            lidClosed: Self.rootDomainFlag("AppleClamshellState"),
            externalDisplay: Self.hasExternalDisplay(),
            onBattery: battery.onBattery,
            batteryPercent: battery.percent,
            thermal: Thermal(ProcessInfo.processInfo.thermalState)
        )
    }

    public func setSleepDisabled(_ disabled: Bool) throws {
        let result = try Command.run("/usr/bin/sudo", ["-n", "/usr/bin/pmset", "-a", "disablesleep", disabled ? "1" : "0"])
        guard result.status == 0 else {
            throw NonSleepError.pmsetFailed(result.stderr.isEmpty ? "exit \(result.status)" : result.stderr)
        }
    }

    public func sleepNow() {
        _ = try? Command.run("/usr/bin/pmset", ["sleepnow"])
    }

    /// Turns the displays off, which locks the session when the screen-lock delay is "immediate".
    public static func displaySleepNow() {
        _ = try? Command.run("/usr/bin/pmset", ["displaysleepnow"])
    }

    private static func rootDomainFlag(_ key: String) -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }
        let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue()
        return (value as? Bool) ?? false
    }

    private static func hasExternalDisplay() -> Bool {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else { return false }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &ids, &count) == .success else { return false }
        return ids.prefix(Int(count)).contains { CGDisplayIsBuiltin($0) == 0 }
    }

    private static func battery() -> (onBattery: Bool, percent: Int?) {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return (false, nil) }
        let source = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        var percent: Int?
        for item in list {
            guard let desc = IOPSGetPowerSourceDescription(info, item)?.takeUnretainedValue() as? [String: Any],
                  desc[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let current = desc[kIOPSCurrentCapacityKey] as? Int,
                  let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0
            else { continue }
            percent = current * 100 / max
        }
        return (source == kIOPSBatteryPowerValue, percent)
    }
}
#endif
