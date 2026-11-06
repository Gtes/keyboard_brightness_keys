import Foundation

enum LoginItem {
    private static let label = AppIdentity.helperID

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
                    NSLocalizedDescriptionKey: "\(AppIdentity.helperFile) not found next to Settings or in Applications.",
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
            _ = Shell.run("/bin/launchctl", ["unload", "-w", plistURL.path])
            let status = Shell.run("/bin/launchctl", ["load", "-w", plistURL.path]).status
            if status != 0 {
                throw NSError(domain: label, code: Int(status), userInfo: [
                    NSLocalizedDescriptionKey: "launchctl could not load the login item.",
                ])
            }
        } else {
            _ = Shell.run("/bin/launchctl", ["unload", "-w", plistURL.path])
            try? FileManager.default.removeItem(at: plistURL)
        }
    }
}
