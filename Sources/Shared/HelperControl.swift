import AppKit

enum HelperControl {
    static var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: AppIdentity.helperID).isEmpty
    }

    static func helperURL() -> URL? {
        appURL(named: AppIdentity.helperFile)
    }

    static func settingsURL() -> URL? {
        appURL(named: AppIdentity.settingsFile)
    }

    @discardableResult
    static func ensureRunning() -> Bool {
        if isRunning { return true }
        guard let url = helperURL() else { return false }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        return true
    }

    static func quit() {
        DistributedNotificationCenter.default().postNotificationName(
            AppIdentity.Note.quitHelper,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: AppIdentity.helperID) {
            app.terminate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if !app.isTerminated {
                    app.forceTerminate()
                }
            }
        }
    }

    static func openSettings() {
        guard let url = settingsURL() else { return }
        NSWorkspace.shared.open(url)
    }

    private static func appURL(named fileName: String) -> URL? {
        let candidates = [
            Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(fileName),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Applications/\(fileName)"),
            URL(fileURLWithPath: "/Applications/\(fileName)"),
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }
}
