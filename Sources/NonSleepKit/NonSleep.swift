import Foundation

public struct Status: Sendable {
    public var power: PowerSnapshot
    /// Live leases after sweeping dead ones.
    public var leases: [Lease]
    /// Why live leases are not being honored right now (low battery, heat).
    public var blockedBy: String?
    /// The flag is set but by something other than NonSleep (e.g. Amphetamine, a manual `pmset`).
    public var setByOtherTool: Bool

    /// Language is passed in rather than read from disk: `Status` is produced inside the engine
    /// lock, and re-reading the config here would widen that lock for a presentation detail.
    public var language: Language = .auto

    public var headline: String {
        if let blockedBy { return L10n.statusPaused(blockedBy)(language) }
        if setByOtherTool { return L10n.statusOtherTool(language) }
        return power.sleepDisabled ? L10n.statusAwake(language) : L10n.statusNormal(language)
    }
}

public enum Policy {
    /// Safety cut-outs that override every lease.
    public static func blocker(
        _ power: PowerSnapshot,
        minBatteryPercent: Int,
        backpackProtection: Bool = true,
        language: Language = .auto
    ) -> String? {
        if power.onBattery, let percent = power.batteryPercent, percent < minBatteryPercent {
            return L10n.blockerBattery(percent, minBatteryPercent)(language)
        }
        if power.thermal >= .serious {
            return L10n.blockerThermal(power.thermal.rawValue)(language)
        }
        if backpackProtection, power.lidClosed, power.onBattery, !power.externalDisplay, power.thermal >= .fair {
            return L10n.blockerBackpack(power.thermal.rawValue)(language)
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
        let blockedBy = live.isEmpty ? nil : Policy.blocker(
            power,
            minBatteryPercent: config.minBatteryPercent,
            backpackProtection: config.backpackProtection,
            language: config.language
        )
        let wanted = !live.isEmpty && blockedBy == nil

        let history = HistoryStore.standard(store: store, config: config)

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
            history.openSession(
                at: now, reason: live.map(\.reason).joined(separator: ", "),
                battery: power.batteryPercent, thermal: power.thermal
            )
        } else if wanted {
            history.observe(thermal: power.thermal)
        } else if store.ownsFlag {
            // Trust the marker over the registry read: clearing is idempotent, a stuck flag is not.
            try self.power.setSleepDisabled(false)
            store.ownsFlag = false
            power.sleepDisabled = false
            history.closeSession(at: now, battery: power.batteryPercent, thermal: power.thermal)
            if config.soundEnabled {
                SoundPlayer.play(soundPath: config.soundPath)
            }
            if config.sleepWhenDone, power.lidClosed, !power.externalDisplay {
                self.power.sleepNow()
            }
        }

        return Status(
            power: power,
            leases: live,
            blockedBy: blockedBy,
            setByOtherTool: power.sleepDisabled && !store.ownsFlag,
            language: config.language
        )
    }
}
