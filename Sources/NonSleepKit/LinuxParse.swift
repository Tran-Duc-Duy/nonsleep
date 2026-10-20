import Foundation

/// Parsers for the Linux text formats NonSleep reads. Pure functions without platform guards,
/// so they're compiled and tested everywhere.
enum LinuxParse {
    struct Inhibitor: Equatable {
        var what: String
        var who: String
        var why: String
        var mode: String
        var pid: Int32
    }

    /// `/proc/<pid>/stat` → parent PID and start time (clock ticks since boot).
    /// `comm` (field 2) may contain spaces and parentheses, so fields are counted after the last ")".
    static func stat(_ text: String) -> (parent: Int32, start: UInt64)? {
        guard let close = text.range(of: ")", options: .backwards) else { return nil }
        let fields = text[close.upperBound...].split(separator: " ")
        // fields[0] is field 3 (state), [1] is field 4 (ppid), [19] is field 22 (starttime).
        guard fields.count > 19, let parent = Int32(fields[1]), let start = UInt64(fields[19]) else { return nil }
        return (parent, start)
    }

    /// `/proc/stat` → boot time in seconds since the epoch (`btime` line).
    static func bootTime(_ text: String) -> UInt64? {
        text.split(separator: "\n")
            .first { $0.hasPrefix("btime ") }
            .flatMap { UInt64($0.dropFirst("btime ".count).trimmingCharacters(in: .whitespaces)) }
    }

    /// `/proc/<pid>/cmdline` → argv (NUL-separated, trailing NUL).
    static func cmdline(_ data: Data) -> [String] {
        guard !data.isEmpty else { return [] }  // kernel threads, or a process we may not read
        return data.split(separator: 0, omittingEmptySubsequences: false)
            .dropLast(data.last == 0 ? 1 : 0)
            .map { String(decoding: $0, as: UTF8.self) }
    }

    /// `busctl get-property …` output for a boolean: "b true" / "b false".
    static func busctlBool(_ text: String) -> Bool? {
        switch text.trimmingCharacters(in: .whitespacesAndNewlines) {
        case "b true": true
        case "b false": false
        default: nil
        }
    }

    /// `busctl --json=short call … ListInhibitors`:
    /// `{"type":"a(ssssuu)","data":[[["sleep","who","why","block",1000,4242], …]]}`.
    static func inhibitors(_ json: String) -> [Inhibitor] {
        guard let object = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any],
              let data = object["data"] as? [Any],
              let rows = data.first as? [[Any]]
        else { return [] }
        return rows.compactMap { row in
            guard row.count >= 6,
                  let what = row[0] as? String, let who = row[1] as? String,
                  let why = row[2] as? String, let mode = row[3] as? String,
                  let pid = (row[5] as? NSNumber)?.int32Value
            else { return nil }
            return Inhibitor(what: what, who: who, why: why, mode: mode, pid: pid)
        }
    }

    /// `/sys/class/power_supply/*` entries → whether we run on battery, and its charge.
    /// A battery that is "Discharging" means no AC; capacity is already a percentage.
    static func battery(_ supplies: [(type: String, status: String?, capacity: String?)]) -> (onBattery: Bool, percent: Int?) {
        let batteries = supplies.filter { $0.type == "Battery" }
        let discharging = batteries.contains { $0.status == "Discharging" }
        let percent = batteries.compactMap { $0.capacity.flatMap { Int($0) } }.first
        return (discharging, percent)
    }
}
