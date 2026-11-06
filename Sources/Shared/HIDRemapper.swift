import Foundation
import os

private let log = Logger(subsystem: AppIdentity.helperID, category: "hid")

/// Remaps MacBook F5/F6 (Dictation / Focus) to keyboard backlight down/up.
final class HIDRemapper {
    private let queue = DispatchQueue(label: "\(AppIdentity.helperID).hid")

    private static let f5Dictation: UInt64 = 0x0000_000C_0000_00CF
    private static let f6Focus: UInt64 = 0x0000_0001_0000_009B
    private static let illuminationDown: UInt64 = 0x0000_00FF_0000_0009
    private static let illuminationUp: UInt64 = 0x0000_00FF_0000_0008
    private static let managedSources: Set<UInt64> = [f5Dictation, f6Focus]

    func sync(enabled: Bool) {
        queue.async { Self.apply(enabled: enabled) }
    }

    func syncAndWait(enabled: Bool) {
        queue.sync { Self.apply(enabled: enabled) }
    }

    private static func apply(enabled: Bool) {
        var mappings = currentMappings().filter { !managedSources.contains($0.src) }
        if enabled {
            mappings.append(Binding(src: f5Dictation, dst: illuminationDown))
            mappings.append(Binding(src: f6Focus, dst: illuminationUp))
        }
        if write(mappings) {
            log.info("remap enabled=\(enabled)")
        } else {
            log.error("hidutil failed")
        }
    }

    private struct Binding {
        var src: UInt64
        var dst: UInt64
    }

    private static func currentMappings() -> [Binding] {
        let output = Shell.run("/usr/bin/hidutil", ["property", "--get", "UserKeyMapping"]).text
        var mappings: [Binding] = []
        for block in output.components(separatedBy: "{").dropFirst() {
            guard let src = integer("HIDKeyboardModifierMappingSrc", in: block),
                  let dst = integer("HIDKeyboardModifierMappingDst", in: block) else { continue }
            mappings.append(Binding(src: src, dst: dst))
        }
        return mappings
    }

    private static func write(_ mappings: [Binding]) -> Bool {
        let rows = mappings.map {
            String(
                format: #"{"HIDKeyboardModifierMappingSrc":0x%llX,"HIDKeyboardModifierMappingDst":0x%llX}"#,
                $0.src,
                $0.dst
            )
        }
        let json = #"{"UserKeyMapping":["# + rows.joined(separator: ",") + "]}"
        return Shell.run("/usr/bin/hidutil", ["property", "--set", json]).status == 0
    }

    private static func integer(_ key: String, in block: String) -> UInt64? {
        guard let line = block.split(separator: "\n").first(where: { $0.contains(key) }) else { return nil }
        guard let digits = line.split(separator: "=").last?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ";")) else { return nil }
        return UInt64(digits)
    }
}
