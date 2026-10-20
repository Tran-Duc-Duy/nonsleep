import Foundation

public struct Status: Sendable {
    public var power: PowerSnapshot
    /// Live leases after sweeping dead ones.
    public var leases: [Lease]
    /// Why live leases are not being honored right now (low battery, heat).
    public var blockedBy: String?
    /// The flag is set but by something other than NonSleep (e.g. Amphetamine, a manual `pmset`).
    public var setByOtherTool: Bool

    public var headline: String {
        if let blockedBy { return "Paused: \(blockedBy)" }
        if setByOtherTool { return "Sleep disabled by another tool" }
        return power.sleepDisabled ? "Stays awake with the lid closed" : "Normal sleep"
    }
}

public enum Policy {
    /// Safety cut-outs that override every lease.
    public static func blocker(_ power: PowerSnapshot, minBatteryPercent: Int) -> String? {
        if power.onBattery, let percent = power.batteryPercent, percent < minBatteryPercent {
            return "battery \(percent)% < \(minBatteryPercent)%"
        }
        if power.thermal >= .serious {
            return "thermal state \(power.thermal.rawValue)"
        }
        return nil
    }
}

/// Converges the `disablesleep` flag to "on iff a live lease exists and it is safe".
/// Every entry point takes a cross-process lock, so the CLI, the menu bar app and the reaper
/// can run concurrently.
public struct NonSleep: Sendable {
    public let store: Store
    public let power: any PowerControl

    /// - Parameter power: defaults to the real machine (`SystemPower`), using `store` on Linux.
    public init(store: Store = .standard, power: (any PowerControl)? = nil) {
        self.store = store
        #if os(Linux)
        self.power = power ?? SystemPower(store: store)
        #else
        self.power = power ?? SystemPower()
        #endif
    }

    public func config() throws -> Config {
        try Config.load(from: store.configURL)
    }

    @discardableResult
    public func hold(_ lease: Lease) throws -> Status {
        try store.locked {
            try store.save(lease)
            do {
                return try apply()
            } catch {
                store.remove(id: lease.id)  // the request failed; don't leave it for the reaper to retry
                throw error
            }
        }
    }

    @discardableResult
    public func release(id: String) throws -> Status {
        try store.locked {
            store.remove(id: id)
            return try apply()
        }
    }

    @discardableResult
    public func releaseAll() throws -> Status {
        try store.locked {
            for lease in store.leases() { store.remove(id: lease.id) }
            return try apply()
        }
    }

    @discardableResult
    public func reconcile() throws -> Status {
        try store.locked { try apply() }
    }

    /// Drops every lease, restores normal sleep, and sleeps the Mac now. While the flag is set,
    /// the Apple-menu Sleep item and the power button cannot sleep the Mac; this can.
    @discardableResult
    public func sleepNow() throws -> Status {
        let status = try releaseAll()
        power.sleepNow()
        return status
    }

    private func apply(now: Date = Date()) throws -> Status {
        // A broken config must never stop the flag from being cleared.
        let config = (try? config()) ?? .defaults
        let bootTime = Processes.bootTime()
        var live: [Lease] = []
        for lease in store.leases() {
            let ownerStart = lease.ownerPID.flatMap { Processes.startTime(of: $0) }
            if lease.isAlive(now: now, bootTime: bootTime, ownerStart: ownerStart) {
                live.append(lease)
            } else {
                store.remove(id: lease.id)
            }
        }

        var power = power.snapshot()
        let blockedBy = live.isEmpty ? nil : Policy.blocker(power, minBatteryPercent: config.minBatteryPercent)
        let wanted = !live.isEmpty && blockedBy == nil

        if wanted, !power.sleepDisabled {
            // Claim before acting: a crash right after pmset must still leave the flag ours to clear.
            store.ownsFlag = true
            do {
                try self.power.setSleepDisabled(true)
            } catch {
                store.ownsFlag = false  // sudo refused, so nothing changed
                throw error
            }
            power.sleepDisabled = true
        } else if !wanted, store.ownsFlag {
            // Trust the marker over the registry read: clearing is idempotent, a stuck flag is not.
            try self.power.setSleepDisabled(false)
            store.ownsFlag = false
            power.sleepDisabled = false
            if config.sleepWhenDone, power.lidClosed, !power.externalDisplay {
                self.power.sleepNow()
            }
        }

        return Status(
            power: power,
            leases: live,
            blockedBy: blockedBy,
            setByOtherTool: power.sleepDisabled && !store.ownsFlag
        )
    }
}
