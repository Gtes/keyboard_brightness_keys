import AppKit

enum HelperControl {
    static var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: AppID.helper).isEmpty
    }

    static func helperURL() -> URL? {
        let neighbors = [
            Bundle.main.bundleURL.deletingLastPathComponent()
                .appendingPathComponent("Keyboard Brightness Keys Helper.app"),
            URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Applications/Keyboard Brightness Keys Helper.app"),
            URL(fileURLWithPath: "/Applications/Keyboard Brightness Keys Helper.app"),
        ]
        return neighbors.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    @discardableResult
    static func ensureRunning() -> Bool {
        if isRunning { return true }
        guard let url = helperURL() else { return false }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        NSWorkspace.shared.openApplication(at: url, configuration: config)
        return true
    }

    static func quit() {
        DistributedNotificationCenter.default().postNotificationName(
            Note.quitHelper,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: AppID.helper) {
            app.terminate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if !app.isTerminated { app.forceTerminate() }
            }
        }
    }

    static func openSettings() {
        let neighbors = [
            Bundle.main.bundleURL.deletingLastPathComponent()
                .appendingPathComponent("Keyboard Brightness Keys.app"),
            URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("Applications/Keyboard Brightness Keys.app"),
            URL(fileURLWithPath: "/Applications/Keyboard Brightness Keys.app"),
        ]
        guard let url = neighbors.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else { return }
        NSWorkspace.shared.open(url)
    }
}
