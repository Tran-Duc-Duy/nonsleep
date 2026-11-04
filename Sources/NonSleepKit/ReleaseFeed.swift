import Foundation

/// Parsing and version ordering for the manual update check. Pure string work: this file opens
/// no connections of any kind. The request itself lives in the menu bar app
/// (`NonSleepBar/UpdateCheck.swift`), so the engine, the CLI and the reaper stay network-free.
public enum ReleaseFeed {
    public struct Release: Equatable, Sendable {
        public var version: String
        public var page: URL

        public init(version: String, page: URL) {
            self.version = version
            self.page = page
        }
    }

    private struct Payload: Decodable {
        let tagName: String
        let htmlURL: String?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
        }
    }

    /// GitHub's `releases/latest` excludes drafts and prereleases, so a beta tag never prompts.
    public static func parse(_ data: Data, fallbackPage: URL) -> Release? {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        let version = payload.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        guard !version.isEmpty else { return nil }
        return Release(version: version, page: payload.htmlURL.flatMap(URL.init(string:)) ?? fallbackPage)
    }

    /// True when `latest` is strictly newer than `current`. Components are compared numerically
    /// (so `0.10.0` beats `0.9.0`), and a release outranks the prerelease of the same number.
    public static func isNewer(_ latest: String, than current: String) -> Bool {
        let (latestNumbers, latestPre) = split(latest)
        let (currentNumbers, currentPre) = split(current)
        for index in 0..<max(latestNumbers.count, currentNumbers.count) {
            let new = index < latestNumbers.count ? latestNumbers[index] : 0
            let old = index < currentNumbers.count ? currentNumbers[index] : 0
            if new != old { return new > old }
        }
        switch (latestPre, currentPre) {
        case (nil, nil): return false
        case (nil, _): return true  // 0.4.0 beats 0.4.0-beta.1
        case (_, nil): return false
        case (let new?, let old?): return new > old
        }
    }

    private static func split(_ version: String) -> ([Int], String?) {
        let trimmed = version.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
        let parts = trimmed.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numbers = parts[0].split(separator: ".").map { Int($0) ?? 0 }
        let prerelease = parts.count > 1 && !parts[1].isEmpty ? String(parts[1]) : nil
        return (numbers, prerelease)
    }
}
