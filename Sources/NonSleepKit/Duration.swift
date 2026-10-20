import Foundation

public enum Duration {
    /// Parses `90s`, `45m`, `3h`, `1h30m`, or a bare number of minutes. Returns seconds.
    public static func parse(_ text: String) -> TimeInterval? {
        let text = text.lowercased()
        if let minutes = Double(text) { return minutes > 0 && minutes.isFinite ? minutes * 60 : nil }
        var total: TimeInterval = 0
        var number = ""
        for character in text {
            if character.isNumber || character == "." {
                number.append(character)
                continue
            }
            let unit: TimeInterval
            switch character {
            case "s": unit = 1
            case "m": unit = 60
            case "h": unit = 3600
            case "d": unit = 86400
            default: return nil
            }
            guard let value = Double(number) else { return nil }
            total += value * unit
            number = ""
        }
        return number.isEmpty && total > 0 ? total : nil
    }

    /// Inverse of `parse`: 0s, 30s, 2m, 1m30s, 3h, 1h5m.
    public static func format(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let parts = [(total / 3600, "h"), (total % 3600 / 60, "m"), (total % 60, "s")].filter { $0.0 > 0 }
        return parts.isEmpty ? "0s" : parts.map { "\($0.0)\($0.1)" }.joined()
    }
}
