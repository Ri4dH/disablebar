import AppKit
import Darwin

/// What the Touch Bar shows when it is on (System Settings › Keyboard › Touch Bar).
enum TouchBarMode: String, CaseIterable, Identifiable {
    case appControls = "appWithControlStrip"
    case expandedControlStrip = "fullControlStrip"
    case functionKeys = "functionKeys"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appControls: return "App Controls"
        case .expandedControlStrip: return "Control Strip"
        case .functionKeys: return "F1–F12 Keys"
        }
    }

    var symbol: String {
        switch self {
        case .appControls: return "square.grid.3x1.below.line.grid.1x2"
        case .expandedControlStrip: return "slider.horizontal.3"
        case .functionKeys: return "fn"
        }
    }
}

/// Helpers that talk to the macOS Touch Bar services.
enum SystemTouchBar {
    private static let agentDomain = "com.apple.touchbar.agent" as CFString
    private static let modeKey = "PresentationModeGlobal" as CFString

    static var mode: TouchBarMode {
        let value = CFPreferencesCopyAppValue(modeKey, agentDomain) as? String
        return value.flatMap(TouchBarMode.init(rawValue:)) ?? .appControls
    }

    /// Changes the Touch Bar layout and reloads the Control Strip so it takes effect.
    static func setMode(_ mode: TouchBarMode) {
        CFPreferencesSetAppValue(modeKey, mode.rawValue as CFString, agentDomain)
        CFPreferencesAppSynchronize(agentDomain)
        restartControlStrip()
    }

    /// Kills ControlStrip (it is relaunched by launchd). SIGKILL also works when
    /// the process is stuck or stopped.
    static func restartControlStrip() {
        run("/usr/bin/killall", ["-KILL", "ControlStrip"])
    }

    /// Restarts TouchBarServer + ControlStrip. TouchBarServer runs as root, so
    /// macOS asks for an administrator password. This is the classic fix for a
    /// frozen, glitching or flickering Touch Bar.
    @discardableResult
    static func restartTouchBarServer() -> Bool {
        let script = "do shell script \"/usr/bin/pkill TouchBarServer; /usr/bin/killall -KILL ControlStrip; exit 0\" with administrator privileges with prompt \"DisableBar wants to restart the Touch Bar.\""
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        return error == nil
    }

    /// PID of the running TouchBarServer (root-owned, so we read it via sysctl).
    static func touchBarServerPID() -> pid_t? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, u_int(mib.count), nil, &size, nil, 0) == 0, size > 0 else { return nil }
        let count = size / MemoryLayout<kinfo_proc>.stride
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count + 16)
        size = procs.count * MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, u_int(mib.count), &procs, &size, nil, 0) == 0 else { return nil }
        let found = size / MemoryLayout<kinfo_proc>.stride
        for var proc in procs.prefix(found) {
            let name = withUnsafeBytes(of: &proc.kp_proc.p_comm) { raw -> String in
                String(decoding: raw.prefix(while: { $0 != 0 }), as: UTF8.self)
            }
            if name == "TouchBarServer" { return proc.kp_proc.p_pid }
        }
        return nil
    }

    /// True when ControlStrip has been suspended (SIGSTOP). This makes the
    /// Touch Bar look frozen, and the Settings layout switch won't apply.
    static func isControlStripSuspended() -> Bool {
        guard let app = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.controlstrip").first else { return false }
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, app.processIdentifier]
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0 else { return false }
        return info.kp_proc.p_stat == SSTOP
    }

    @discardableResult
    private static func run(_ path: String, _ args: [String]) -> Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do { try task.run() } catch { return -1 }
        task.waitUntilExit()
        return task.terminationStatus
    }
}
