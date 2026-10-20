#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

/// Runs tools directly (no shell). Built on `posix_spawn` + `waitpid` rather than Foundation's
/// `Process`, whose `waitUntilExit()` never returns on Linux (Swift 6.3), and so that both
/// platforms share one code path.
public enum Command {
    public struct Result: Sendable {
        public var status: Int32
        public var stdout: String
        public var stderr: String
    }

    /// Runs `path` with stdin from /dev/null and returns its exit status and trimmed output.
    public static func run(_ path: String, _ arguments: [String]) throws -> Result {
        let out = try makePipe(), err = try makePipe()
        let pid: pid_t
        do {
            pid = try spawn(path, arguments, stdout: out.write, stderr: err.write, closing: [out.read, err.read])
        } catch {
            [out.read, out.write, err.read, err.write].forEach { _ = close($0) }
            throw error
        }
        close(out.write)
        close(err.write)
        // Drain stderr on another thread so neither pipe can fill up and stall the child.
        let errorData = Box()
        let drained = DispatchSemaphore(value: 0)
        Thread {
            errorData.value = FileHandle(fileDescriptor: err.read, closeOnDealloc: true).readDataToEndOfFile()
            drained.signal()
        }.start()
        let outData = FileHandle(fileDescriptor: out.read, closeOnDealloc: true).readDataToEndOfFile()
        drained.wait()
        return Result(status: wait(pid), stdout: text(outData), stderr: text(errorData.value))
    }

    /// Starts `path` with stdin from /dev/null and stdout/stderr on `output` (or /dev/null) and
    /// returns its PID without waiting.
    public static func spawn(_ path: String, _ arguments: [String], output: Int32? = nil) throws -> pid_t {
        try spawn(path, arguments, stdout: output, stderr: output, closing: [])
    }

    /// Exit status of `pid` (128 + signal if it was killed); blocks until it ends.
    public static func wait(_ pid: pid_t) -> Int32 {
        var status: Int32 = 0
        while waitpid(pid, &status, 0) == -1, errno == EINTR {}
        let signal = status & 0x7f
        return signal == 0 ? (status >> 8) & 0xff : 128 + signal
    }

    private static func spawn(
        _ path: String, _ arguments: [String], stdout: Int32?, stderr: Int32?, closing: [Int32]
    ) throws -> pid_t {
        #if canImport(Darwin)
        var actions: posix_spawn_file_actions_t?
        #else
        var actions = posix_spawn_file_actions_t()
        #endif
        posix_spawn_file_actions_init(&actions)
        defer { posix_spawn_file_actions_destroy(&actions) }
        posix_spawn_file_actions_addopen(&actions, 0, "/dev/null", O_RDONLY, 0)
        if let stdout { posix_spawn_file_actions_adddup2(&actions, stdout, 1) } else {
            posix_spawn_file_actions_addopen(&actions, 1, "/dev/null", O_WRONLY, 0)
        }
        if let stderr { posix_spawn_file_actions_adddup2(&actions, stderr, 2) } else {
            posix_spawn_file_actions_addopen(&actions, 2, "/dev/null", O_WRONLY, 0)
        }
        for fd in closing { posix_spawn_file_actions_addclose(&actions, fd) }

        let argv = ([path] + arguments).map { strdup($0) } + [nil]
        defer { argv.forEach { free($0) } }
        var pid: pid_t = 0
        let result = posix_spawn(&pid, path, &actions, nil, argv, environ)
        guard result == 0 else { throw POSIXError(POSIXErrorCode(rawValue: result) ?? .EIO) }
        return pid
    }

    private static func makePipe() throws -> (read: Int32, write: Int32) {
        var fds: [Int32] = [0, 0]
        guard pipe(&fds) == 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        // Never leak these into other children spawned concurrently.
        _ = fcntl(fds[0], F_SETFD, FD_CLOEXEC)
        _ = fcntl(fds[1], F_SETFD, FD_CLOEXEC)
        return (fds[0], fds[1])
    }

    private static func text(_ data: Data) -> String {
        String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Written once by the reader thread before `drained.signal()`, read after `drained.wait()`.
    private final class Box: @unchecked Sendable {
        var value = Data()
    }
}
