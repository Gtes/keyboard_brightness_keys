import AppKit

enum HelperControl {
    static var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: AppIdentity.helperID).isEmpty
    }

    static func helperURL() -> URL? {
        let nested = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/\(AppIdentity.helperFile)")
        if FileManager.default.fileExists(atPath: nested.path) {
            return nested
        }
        return appURL(named: AppIdentity.helperFile)
    }

    static func settingsURL() -> URL? {
        if Bundle.main.bundleIdentifier == AppIdentity.settingsID {
            return Bundle.main.bundleURL
        }
        // Helper lives at …/Keyboard Brightness Keys.app/Contents/Library/LoginItems/Helper.app
        let nestedParent = Bundle.main.bundleURL
            .deletingLastPathComponent() // LoginItems
            .deletingLastPathComponent() // Library
            .deletingLastPathComponent() // Contents
            .deletingLastPathComponent() // Settings.app
        if nestedParent.lastPathComponent == AppIdentity.settingsFile,
           FileManager.default.fileExists(atPath: nestedParent.path) {
            return nestedParent
        }
        return appURL(named: AppIdentity.settingsFile)
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
