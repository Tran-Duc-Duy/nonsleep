#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation
import NonSleepKit

let usage = """
    usage: nonsleep <command>

      status               show lid-closed mode, leases, agent activity, power
      on [DURATION]        keep awake with the lid closed until `off`, DURATION (90m, 3h), or reboot
      off                  release every lease and restore normal sleep
      sleep                release every lease and put the Mac to sleep now
      run [--] CMD [ARG…]  keep awake while CMD runs; exits with CMD's status
      wait TARGET…         keep awake while the given PIDs or process names (claude, omp) run
      auto                 keep awake while agents are working (see `nonsleep config`)
      reap                 sweep dead leases and re-apply state (run by the LaunchAgent)
      config               print the config path and effective config
      setup [--remove]     install (or remove) the sudoers rule, reaper LaunchAgent and ~/.local/bin link
      integrate [AGENT…] [--remove]
                           add (or remove) hooks for claude, cursor, antigravity; no AGENT: show status
      hook AGENT EVENT     called by those hooks with the event JSON on stdin

    """

let engine = NonSleep()

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("nonsleep: \(message)\n".utf8))
    exit(1)
}

func log(_ message: String) {
    let time = Date().formatted(date: .omitted, time: .standard)
    FileHandle.standardError.write(Data("[\(time)] \(message)\n".utf8))
}

func clock(_ date: Date) -> String {
    date.formatted(date: .omitted, time: .shortened)
}

func printStatus(_ status: Status, agents: [String]) {
    let power = status.power
    var facts = [power.lidClosed ? "lid closed" : "lid open", power.onBattery ? "battery power" : "AC power"]
    if let percent = power.batteryPercent { facts.append("battery \(percent)%") }
    if power.externalDisplay { facts.append("external display") }
    facts.append("thermal \(power.thermal.rawValue)")

    print(status.headline)
    print("  " + facts.joined(separator: " · "))
    print(status.leases.isEmpty ? "leases: none" : "leases:")
    for lease in status.leases {
        print("  \(lease.reason)  (\(lease.detail))")
    }
    print(agents.isEmpty ? "agents: idle" : "agents: " + agents.joined(separator: ", "))
    #if os(macOS)
    if !Setup.sudoersInstalled {
        print("sudoers: not installed — run `nonsleep setup` so NonSleep may toggle `pmset disablesleep`")
    }
    if !Setup.reaperInstalled {
        print("reaper: not installed — run `nonsleep setup` so crashed or expired leases get cleared")
    }
    #endif
}

// MARK: - Foreground holders (run / wait / auto)

enum Step {
    case hold(String)
    case idle
    case exit(Int32)
}

/// Holds a lease owned by this process, re-evaluating `step` periodically.
/// Signals release the lease before exiting; `kill -9` is covered by the reaper.
@MainActor
final class Holder {
    let id: String
    private var step: () -> Step = { .idle }
    private var onSignal: ((Int32) -> Void)?
    private var lastLine: String?
    /// Errors before the first success (e.g. no sudoers rule) are fatal; later ones are retried
    /// on the next tick so a transient failure never orphans a `run` child.
    private var healthy = false
    private var sources: [any DispatchSourceProtocol] = []

    init(id: String) {
        self.id = id
    }

    func apply(_ next: Step) {
        do {
            switch next {
            case .hold(let reason):
                report(reason, try engine.hold(.owned(id: id, reason: reason)))
            case .idle:
                report(nil, try engine.release(id: id))
            case .exit(let code):
                _ = try? engine.release(id: id)
                exit(code)
            }
            healthy = true
        } catch {
            guard healthy else {
                _ = try? engine.release(id: id)
                fail("\(error)")
            }
            report(nil, "error: \(error) (retrying)")
        }
    }

    func run(
        every interval: TimeInterval,
        onSignal: ((Int32) -> Void)? = nil,
        step: @escaping () -> Step
    ) -> Never {
        self.step = step
        self.onSignal = onSignal
        for signalNumber in [SIGINT, SIGTERM, SIGHUP] {
            signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { [unowned self] in
                MainActor.assumeIsolated {
                    if let onSignal = self.onSignal { onSignal(signalNumber) } else { self.apply(.exit(128 + signalNumber)) }
                }
            }
            source.resume()
            sources.append(source)
        }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: interval)
        timer.setEventHandler { [unowned self] in
            MainActor.assumeIsolated { self.apply(self.step()) }
        }
        timer.resume()
        sources.append(timer)
        dispatchMain()
    }

    /// Exits with the child's status once it ends. A blocking `waitpid` on a helper thread works
    /// the same on macOS and Linux (dispatch process sources are kqueue-only) and can't miss an
    /// early exit.
    func watch(child pid: pid_t) {
        Thread {
            var status: Int32 = 0
            while waitpid(pid, &status, 0) == -1, errno == EINTR {}
            let signalled = status & 0x7f
            let code = signalled == 0 ? (status >> 8) & 0xff : 128 + signalled
            DispatchQueue.main.async {
                MainActor.assumeIsolated { self.apply(.exit(code)) }
            }
        }.start()
    }

    private func report(_ reason: String?, _ status: Status) {
        report(reason, status.headline)
    }

    private func report(_ reason: String?, _ headline: String) {
        let line = reason.map { "\(headline) — \($0)" } ?? headline
        if line != lastLine { log(line) }
        lastLine = line
    }
}

@MainActor
func runCommand(_ arguments: [String]) -> Never {
    let command = arguments.first == "--" ? Array(arguments.dropFirst()) : arguments
    guard let executable = command.first else { fail("run: missing command") }
    let holder = Holder(id: "run-\(getpid())")
    let reason = "run: " + command.joined(separator: " ")
    holder.apply(.hold(reason))

    // posix_spawn (not Process) keeps the child in our process group so interactive
    // TUIs like `claude` still own the terminal and receive Ctrl-C directly.
    var pid: pid_t = 0
    let argv = command.map { strdup($0) } + [nil]
    let spawned = posix_spawnp(&pid, executable, nil, nil, argv, environ)
    argv.forEach { free($0) }
    guard spawned == 0 else {
        _ = try? engine.release(id: holder.id)
        fail("run: \(executable): \(String(cString: strerror(spawned)))")
    }
    holder.watch(child: pid)
    // Ctrl-C already reaches the child through the terminal; forward only TERM/HUP.
    holder.run(every: 15, onSignal: { if $0 != SIGINT { kill(pid, $0) } }) { .hold(reason) }
}

@MainActor
func waitFor(_ targets: [String]) -> Never {
    guard !targets.isEmpty else { fail("wait: give at least one PID or process name") }
    var pids: [(pid: pid_t, start: UInt64)] = []
    var names: [String] = []
    for target in targets {
        if let pid = pid_t(target) {
            guard let start = Processes.startTime(of: pid) else { fail("wait: no process with pid \(pid)") }
            pids.append((pid, start))
        } else {
            guard !Processes.pids(named: target).isEmpty else { fail("wait: no running process named \(target)") }
            names.append(target)
        }
    }
    let holder = Holder(id: "wait-\(getpid())")
    holder.run(every: 10) {
        let alive = pids.filter { Processes.startTime(of: $0.pid) == $0.start }.map { "pid \($0.pid)" }
            + names.filter { !Processes.pids(named: $0).isEmpty }
        return alive.isEmpty ? .exit(0) : .hold("wait: " + alive.joined(separator: ", "))
    }
}

@MainActor
func auto() -> Never {
    let config: Config
    do { config = try engine.config() } catch { fail("\(error)") }
    var grace = Grace(seconds: config.graceSeconds)
    let holder = Holder(id: "auto-\(getpid())")
    holder.run(every: 10) {
        let agents = Agents.activity(config: config)
        guard grace.update(active: !agents.isEmpty) else { return .idle }
        return .hold(agents.isEmpty ? "auto: grace period" : "auto: " + agents.joined(separator: ", "))
    }
}

// MARK: - Entry point

var arguments = Array(CommandLine.arguments.dropFirst())
let command = arguments.isEmpty ? "status" : arguments.removeFirst()

/// Runs inside an agent's hook: must print the neutral response and exit 0 whatever happens,
/// so a NonSleep problem can never block or alter the agent.
func hook(_ arguments: [String]) -> Never {
    guard arguments.count == 2, let agent = HookAgent(rawValue: arguments[0]) else { exit(0) }
    let decision = Hooks.decide(agent: agent, event: arguments[1], payload: FileHandle.standardInput.readDataToEndOfFile())
    if !decision.response.isEmpty { print(decision.response) }
    do {
        switch decision.action {
        case .working:
            let minutes = ((try? engine.config()) ?? .defaults).hookTimeoutMinutes
            let expiresAt = Date().addingTimeInterval(TimeInterval(minutes * 60))
            let lease = Processes.hookOwner().map { Lease.owned(id: decision.leaseID, reason: decision.reason, by: $0, expiresAt: expiresAt) }
                ?? .detached(id: decision.leaseID, reason: decision.reason, expiresAt: expiresAt)
            try engine.hold(lease)
        case .finished:
            try engine.release(id: decision.leaseID)
        case nil:
            break
        }
    } catch {
        FileHandle.standardError.write(Data("nonsleep: \(error)\n".utf8))
    }
    exit(0)
}

func integrate(_ arguments: [String]) throws {
    let remove = arguments.contains("--remove")
    let names = arguments.filter { $0 != "--remove" }
    let agents = try names.contains("all") ? HookAgent.allCases : names.map { name in
        guard let agent = HookAgent(rawValue: name) else { throw NonSleepError.unknownAgent(name) }
        return agent
    }
    for agent in agents {
        try remove ? Integration.remove(agent) : Integration.install(agent)
        print("\(agent.displayName): \(remove ? "hooks removed from" : "hooks added to") \(agent.configURL.path)")
    }
    if agents.isEmpty {
        print("omp: built in (power assertion \"omp agent session\")")
        for agent in HookAgent.allCases {
            let state = Integration.isInstalled(agent) ? "installed" : "not installed — nonsleep integrate \(agent.rawValue)"
            print("\(agent.displayName): \(state)")
        }
    }
}

do {
    switch command {
    case "status":
        let config = (try? engine.config()) ?? .defaults
        printStatus(try engine.reconcile(), agents: Agents.activity(config: config))
    case "on":
        guard arguments.count <= 1 else { fail("on: expected at most one DURATION") }
        let duration = try arguments.first.map { text in
            guard let seconds = Duration.parse(text) else { throw NonSleepError.invalidDuration(text) }
            return seconds
        }
        let expiresAt = duration.map { Date().addingTimeInterval($0) }
        let reason = expiresAt.map { "manual until \(clock($0))" } ?? "manual until `nonsleep off`"
        let status = try engine.hold(.detached(id: "manual", reason: reason, expiresAt: expiresAt))
        print("\(status.headline) — \(reason)")
    case "off":
        print(try engine.releaseAll().headline)
    case "sleep":
        try engine.sleepNow()
    case "run":
        runCommand(arguments)
    case "wait":
        waitFor(arguments)
    case "auto":
        auto()
    case "reap":
        try engine.reconcile()
    case "config":
        print(engine.store.configURL.path)
        print(try engine.config().json())
    case "setup":
        #if os(macOS)
        if arguments.contains("--remove") {
            _ = try? engine.releaseAll()
            try Setup.remove()
            print("Removed the sudoers rule, reaper LaunchAgent and ~/.local/bin/nonsleep link.")
        } else {
            try Setup.install(cli: Integration.cliPath())
            print("Setup complete: sudoers rule, reaper LaunchAgent, \(Setup.cliLinkURL.path) → \(Integration.cliPath())")
        }
        #else
        print("Nothing to set up on Linux: NonSleep uses a logind inhibitor lock, which needs no root.")
        #endif
    #if os(Linux)
    case "keeper":
        Keeper.run(engine: engine)
    #endif
    case "integrate":
        try integrate(arguments)
    case "hook":
        hook(arguments)
    case "help", "-h", "--help":
        print(usage, terminator: "")
    default:
        FileHandle.standardError.write(Data(usage.utf8))
        exit(2)
    }
} catch {
    fail("\(error)")
}
