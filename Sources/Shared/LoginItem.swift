import Foundation

enum LoginItem {
    private static let label = "com.fkeysremap.brightnesskeys.helper"
    private static var plistURL: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            guard let helper = HelperControl.helperURL() else {
                throw NSError(domain: label, code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Keyboard Brightness Keys Helper.app not found in Applications",
                ])
            }
            let plist: [String: Any] = [
                "Label": label,
                "ProgramArguments": ["/usr/bin/open", "-a", helper.path],
                "RunAtLoad": true,
            ]
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try FileManager.default.createDirectory(
                at: plistURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: plistURL)
            _ = run("/bin/launchctl", ["load", "-w", plistURL.path])
        } else {
            _ = run("/bin/launchctl", ["unload", "-w", plistURL.path])
            try? FileManager.default.removeItem(at: plistURL)
        }
    }

    @discardableResult
    private static func run(_ path: String, _ args: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do { try process.run() } catch { return 1 }
        process.waitUntilExit()
        return process.terminationStatus
    }
}
