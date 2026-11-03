import Foundation

/// Plays the "work finished" chime by spawning the system audio player, never by linking an
/// audio framework.
///
/// Two reasons, both load-bearing:
/// - `NSSound.play()` is asynchronous, so a chime started by `nonsleep off` or by the reaper is
///   cut off when that process exits milliseconds later. A separate player process outlives it.
/// - It keeps `AppKit` out of `NonSleepKit`, and so out of the headless CLI.
public enum SoundPlayer {
    #if os(macOS)
    static let player = "/usr/bin/afplay"
    static let fallbackSound = "/System/Library/Sounds/Glass.aiff"
    #else
    static let player = "/usr/bin/paplay"
    static let fallbackSound = "/usr/share/sounds/freedesktop/stereo/complete.oga"
    #endif

    /// - Parameter soundPath: a user-supplied file; the system sound is used when it is `nil`
    ///   or missing, so a bad config path still chimes instead of failing silently.
    public static func play(soundPath: String? = nil) {
        let exists = { FileManager.default.fileExists(atPath: $0) }
        guard exists(player) else { return }
        let sound = soundPath.flatMap { exists($0) ? $0 : nil } ?? fallbackSound
        guard exists(sound), let pid = try? Command.spawn(player, [sound]) else { return }
        // Reap on a thread: the player outlives a short-lived CLI, and a long-lived menu bar app
        // must not accumulate zombies. Ignoring SIGCHLD instead would break `Command.run`'s waitpid.
        Thread { _ = Command.wait(pid) }.start()
    }
}
