import Foundation

/// Maps Caps Lock → Escape using `hidutil` (no special permissions needed).
///
/// Handy on Touch Bar Macs, which have no physical Esc key. Existing user key
/// mappings are preserved; only our own entry is added or removed. The mapping
/// lasts until logout/reboot, so the app re-applies it at launch.
enum KeyRemapper {
    private static let capsLock: UInt64 = 0x7_0000_0039
    private static let escape: UInt64 = 0x7_0000_0029

    static var isCapsLockMappedToEscape: Bool {
        currentMappings().contains { $0.src == capsLock && $0.dst == escape }
    }

    static func setCapsLockToEscape(_ enabled: Bool) {
        var mappings = currentMappings().filter { $0.src != capsLock }
        if enabled { mappings.append((capsLock, escape)) }
        apply(mappings)
    }

    // MARK: - hidutil plumbing

    private typealias Mapping = (src: UInt64, dst: UInt64)

    private static func currentMappings() -> [Mapping] {
        let output = hidutil(["property", "--get", "UserKeyMapping"])
        // Output is an old-style plist array of dictionaries; pick the pairs out.
        var mappings: [Mapping] = []
        var src: UInt64?
        var dst: UInt64?
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: "=").map { $0.trimmingCharacters(in: .whitespaces.union(.init(charactersIn: ";"))) }
            guard parts.count == 2, let value = UInt64(parts[1]) else { continue }
            if parts[0] == "HIDKeyboardModifierMappingSrc" { src = value }
            if parts[0] == "HIDKeyboardModifierMappingDst" { dst = value }
            if let s = src, let d = dst {
                mappings.append((s, d))
                src = nil
                dst = nil
            }
        }
        return mappings
    }

    private static func apply(_ mappings: [Mapping]) {
        let entries = mappings.map {
            "{\"HIDKeyboardModifierMappingSrc\":\($0.src),\"HIDKeyboardModifierMappingDst\":\($0.dst)}"
        }
        let json = "{\"UserKeyMapping\":[\(entries.joined(separator: ","))]}"
        _ = hidutil(["property", "--set", json])
    }

    @discardableResult
    private static func hidutil(_ args: [String]) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        task.arguments = args
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do { try task.run() } catch { return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return String(decoding: data, as: UTF8.self)
    }
}
