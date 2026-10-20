#if os(macOS)
import Darwin
import Foundation
import IOKit.pwr_mgt

extension Processes {
    /// Process start time in microseconds since the epoch; `nil` when the process does not exist.
    /// Together with the PID this identifies a process even if the PID is later reused.
    public static func startTime(of pid: pid_t) -> UInt64? {
        bsdInfo(pid).map { $0.pbi_start_tvsec * 1_000_000 + $0.pbi_start_tvusec }
    }

    public static func parent(of pid: pid_t) -> pid_t? {
        bsdInfo(pid).map { pid_t($0.pbi_ppid) }
    }
    private static func bsdInfo(_ pid: pid_t) -> proc_bsdinfo? {
        var info = proc_bsdinfo()
        let size = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, size) == size else { return nil }
        return info
    }

    /// Boot time in seconds since the epoch. Leases never survive a reboot.
    public static func bootTime() -> UInt64 {
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        var time = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctl(&mib, 2, &time, &size, nil, 0) == 0 else { return 0 }
        return UInt64(time.tv_sec)
    }

    public static func allPIDs() -> [pid_t] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 32)
        let count = pids.withUnsafeMutableBytes { proc_listallpids($0.baseAddress, Int32($0.count)) }
        return pids.prefix(Int(max(count, 0))).filter { $0 > 0 }
    }

    /// `argv` of a process owned by the current user; empty if unreadable.
    public static func arguments(of pid: pid_t) -> [String] {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return [] }
        var buffer = [UInt8](repeating: 0, count: size)
        guard sysctl(&mib, 3, &buffer, &size, nil, 0) == 0, size > MemoryLayout<Int32>.size else { return [] }
        // Layout: argc, exec path, NUL padding, argv[0..<argc], env...
        let argc = Int(buffer.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) })
        var index = MemoryLayout<Int32>.size
        while index < size, buffer[index] != 0 { index += 1 }
        while index < size, buffer[index] == 0 { index += 1 }
        var arguments: [String] = []
        while arguments.count < argc, index < size {
            let start = index
            while index < size, buffer[index] != 0 { index += 1 }
            arguments.append(String(decoding: buffer[start..<index], as: UTF8.self))
            index += 1
        }
        return arguments
    }
}

extension PowerAssertion {
    /// Every power assertion currently held on the system (what `pmset -g assertions` lists).
    public static func all() -> [PowerAssertion] {
        var raw: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&raw) == kIOReturnSuccess,
              let byPID = raw?.takeRetainedValue() as NSDictionary?
        else { return [] }
        var result: [PowerAssertion] = []
        for (key, value) in byPID {
            guard let pid = (key as? NSNumber)?.int32Value, let list = value as? [[String: Any]] else { continue }
            for assertion in list {
                if let name = assertion[kIOPMAssertionNameKey] as? String {
                    result.append(PowerAssertion(pid: pid, name: name))
                }
            }
        }
        return result
    }
}
#endif
