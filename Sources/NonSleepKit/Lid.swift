#if os(macOS)
import Foundation
import IOKit
import IOKit.pwr_mgt

/// Reports lid open/close as it happens, via the root power domain's clamshell message,
/// delivered on the main run loop.
///
/// `@unchecked Sendable`: `port`/`notifier` are written once in `init` and read only in `deinit`;
/// `onChange` is main-actor isolated and only invoked from the main run loop.
public final class LidMonitor: @unchecked Sendable {
    /// `kIOPMMessageClamshellStateChange` = iokit_family_msg(sub_iokit_powermanagement, 0x100);
    /// the C macro isn't importable.
    static let clamshellStateChange: UInt32 = 0xE003_4100
    /// `kClamshellStateBit` in the message argument: set when the lid is closed.
    static let closedBit: UInt = 1 << 0

    private let onChange: @MainActor (_ closed: Bool) -> Void
    private var port: IONotificationPortRef?
    private var notifier: io_object_t = 0

    public init(onChange: @escaping @MainActor (_ closed: Bool) -> Void) {
        self.onChange = onChange
        let root = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard root != 0 else { return }
        defer { IOObjectRelease(root) }
        guard let port = IONotificationPortCreate(kIOMainPortDefault) else { return }
        self.port = port
        CFRunLoopAddSource(
            CFRunLoopGetMain(), IONotificationPortGetRunLoopSource(port).takeUnretainedValue(), .commonModes
        )
        IOServiceAddInterestNotification(
            port, root, kIOGeneralInterest,
            { refcon, _, messageType, argument in
                guard messageType == LidMonitor.clamshellStateChange, let refcon else { return }
                let monitor = Unmanaged<LidMonitor>.fromOpaque(refcon).takeUnretainedValue()
                let closed = UInt(bitPattern: argument) & LidMonitor.closedBit != 0
                MainActor.assumeIsolated { monitor.onChange(closed) }
            },
            Unmanaged.passUnretained(self).toOpaque(), &notifier
        )
    }

    deinit {
        if notifier != 0 { IOObjectRelease(notifier) }
        if let port { IONotificationPortDestroy(port) }
    }
}
#endif
