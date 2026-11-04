import Foundation

/// Thresholds and retry budget that decide when heat suspends lid-closed mode.
///
/// A closed lid removes the keyboard deck from the thermal path, so the same workload that is
/// comfortable with the lid open can climb into throttling territory once the Mac is shut.
/// NonSleep therefore stops at a *configurable* ceiling rather than only at the hardware's own
/// `serious` state, and retries a bounded number of times once the machine has cooled.
public struct ThermalPolicy: Sendable, Equatable {
    /// Lid-closed mode stops at or above this state.
    public var limit: Thermal
    /// Stricter ceiling while the lid is closed, on battery, with no external display (backpack).
    public var backpackLimit: Thermal
    public var backpackProtection: Bool
    /// Automatic resumes allowed per episode; `0` means "never resume on its own".
    public var retryLimit: Int
    /// How long the Mac must be back under the ceiling before a resume is granted.
    public var cooldown: TimeInterval
    /// A resumed run that overheats again sooner than this proves cooling isn't helping, so the
    /// episode locks out immediately instead of burning the rest of the retry budget. `0` disables.
    public var minRun: TimeInterval

    public init(
        limit: Thermal, backpackLimit: Thermal, backpackProtection: Bool,
        retryLimit: Int, cooldown: TimeInterval, minRun: TimeInterval
    ) {
        self.limit = limit
        self.backpackLimit = backpackLimit
        self.backpackProtection = backpackProtection
        self.retryLimit = max(0, retryLimit)
        self.cooldown = max(0, cooldown)
        self.minRun = max(0, minRun)
    }

    public init(config: Config) {
        self.init(
            limit: config.thermalLimit,
            backpackLimit: config.backpackThermalLimit,
            backpackProtection: config.backpackProtection,
            retryLimit: config.thermalRetryLimit,
            cooldown: TimeInterval(config.thermalCooldownMinutes) * 60,
            minRun: TimeInterval(config.thermalMinRunMinutes) * 60
        )
    }

    /// True while the machine is enclosed: no deck convection, no external display, no charger.
    public func isBackpack(_ power: PowerSnapshot) -> Bool {
        backpackProtection && power.lidClosed && power.onBattery && !power.externalDisplay
    }

    /// The thermal state that stops lid-closed mode right now.
    public func ceiling(for power: PowerSnapshot) -> Thermal {
        isBackpack(power) ? min(limit, backpackLimit) : limit
    }

    public func isTooHot(_ power: PowerSnapshot) -> Bool {
        power.thermal >= ceiling(for: power)
    }
}

/// What the guard wants to happen to the leases right now.
public enum ThermalVerdict: Equatable, Sendable {
    /// Cool enough (or never tripped): leases may hold the flag.
    case run
    /// Over the ceiling: lid-closed mode is suspended until the Mac cools.
    case tripped(Thermal, backpack: Bool)
    /// Back under the ceiling, waiting out the cooldown before resume `attempt` of `limit`.
    case cooling(remaining: TimeInterval, attempt: Int, limit: Int)
    /// Retry budget spent, or a resumed run overheated too quickly. Needs manual action.
    case lockedOut(trips: Int)

    public var allowsHold: Bool { self == .run }
}

/// Retry bookkeeping for one *episode* — the span during which at least one lease is live.
/// Persisted in the store so the CLI, the menu bar app and the reaper share a single budget.
public struct ThermalGuard: Codable, Sendable, Equatable {
    /// Overheat events seen in this episode.
    public var trips: Int
    /// Automatic resumes already granted in this episode.
    public var resumes: Int
    /// Set while cooling down, `nil` while running.
    public var trippedAt: Date?
    /// When the last automatic resume happened; used to spot a run that overheats straight away.
    public var resumedAt: Date?
    /// No further automatic resumes this episode.
    public var lockedOut: Bool

    public static let idle = ThermalGuard()

    public init(
        trips: Int = 0, resumes: Int = 0, trippedAt: Date? = nil,
        resumedAt: Date? = nil, lockedOut: Bool = false
    ) {
        self.trips = trips
        self.resumes = resumes
        self.trippedAt = trippedAt
        self.resumedAt = resumedAt
        self.lockedOut = lockedOut
    }

    public var isIdle: Bool { self == .idle }

    /// Pure state machine. Feed one snapshot per reconcile; returns the next state and the verdict.
    public func step(power: PowerSnapshot, policy: ThermalPolicy, now: Date) -> (ThermalGuard, ThermalVerdict) {
        var next = self
        guard !lockedOut else { return (next, .lockedOut(trips: next.trips)) }

        if policy.isTooHot(power) {
            if next.trippedAt == nil {
                next.trips += 1
                next.trippedAt = now
                let burnedOutFast = next.resumedAt.map {
                    policy.minRun > 0 && now.timeIntervalSince($0) < policy.minRun
                } ?? false
                if burnedOutFast || next.resumes >= policy.retryLimit { next.lockedOut = true }
            }
            next.resumedAt = nil
            return (
                next,
                next.lockedOut
                    ? .lockedOut(trips: next.trips)
                    : .tripped(power.thermal, backpack: policy.isBackpack(power))
            )
        }

        guard let trippedAt = next.trippedAt else { return (next, .run) }

        let cooling = now.timeIntervalSince(trippedAt)
        guard cooling >= policy.cooldown else {
            return (next, .cooling(
                remaining: policy.cooldown - cooling,
                attempt: next.resumes + 1,
                limit: policy.retryLimit
            ))
        }
        guard next.resumes < policy.retryLimit else {
            next.lockedOut = true
            return (next, .lockedOut(trips: next.trips))
        }
        next.resumes += 1
        next.trippedAt = nil
        next.resumedAt = now
        return (next, .run)
    }
}
