import Foundation
import NonSleepKit

/// The one place in NonSleep that touches the network, and only when someone clicks the button.
///
/// Deliberately *not* a background check: no timer, no check at launch, no identifiers, no
/// download. It reads the latest release tag from the GitHub API and compares it with the running
/// version; installing an update stays `brew upgrade` or a manual download. The request carries
/// nothing but the version in the User-Agent, and the session is ephemeral (no cookies, no cache,
/// no credentials). Parsing and version ordering live in `NonSleepKit/ReleaseFeed.swift`, which
/// is why the CLI, the engine and the reaper contain no network code at all.
enum UpdateCheck {
    static let releasesPage = URL(string: "https://github.com/Tran-Duc-Duy/nonsleep/releases/latest")!
    static let endpoint = URL(string: "https://api.github.com/repos/Tran-Duc-Duy/nonsleep/releases/latest")!

    enum Outcome: Equatable, Sendable {
        case upToDate(String)
        case available(ReleaseFeed.Release)
        case failed(String)
    }

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }

    static func run(
        current: String = NonSleepVersion.current,
        endpoint: URL = UpdateCheck.endpoint,
        session: URLSession = UpdateCheck.session()
    ) async -> Outcome {
        var request = URLRequest(url: endpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("NonSleep/\(current)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return .failed("HTTP \(http.statusCode)")
            }
            guard let release = ReleaseFeed.parse(data, fallbackPage: releasesPage) else {
                return .failed("unreadable release feed")
            }
            return ReleaseFeed.isNewer(release.version, than: current)
                ? .available(release)
                : .upToDate(release.version)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
