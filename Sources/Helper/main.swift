import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = HelperAppDelegate()
app.delegate = delegate
app.run()

final class HelperAppDelegate: NSObject, NSApplicationDelegate {
    private let hid = HIDRemapper()
    private var statusItem: NSStatusItem?
    private var menu = NSMenu()
    private var activity: NSObjectProtocol?
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        if alreadyRunning {
            NSApp.terminate(nil)
            return
        }

        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: "Keyboard Brightness Keys Helper"
        )

        applyConfig()
        updateMenuIcon()

        observers = [
            DistributedNotificationCenter.default().addObserver(
                forName: Note.configChanged, object: nil, queue: .main
            ) { [weak self] _ in self?.applyConfig() },
            DistributedNotificationCenter.default().addObserver(
                forName: Note.showMenuIcon, object: nil, queue: .main
            ) { [weak self] _ in self?.updateMenuIcon() },
            DistributedNotificationCenter.default().addObserver(
                forName: Note.quitHelper, object: nil, queue: .main
            ) { _ in NSApp.terminate(nil) },
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
            ) { [weak self] _ in self?.applyConfig() },
        ]
    }

    func applicationWillTerminate(_ notification: Notification) {
        hid.syncAndWait(enabled: false)
    }

    private var alreadyRunning: Bool {
        NSRunningApplication.runningApplications(withBundleIdentifier: AppID.helper)
            .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    }

    private func applyConfig() {
        hid.sync(enabled: Config.enabled)
        rebuildMenu()
    }

    private func updateMenuIcon() {
        if Config.menuIconVisible {
            installStatusItem()
        } else {
            removeStatusItem()
        }
    }

    private func installStatusItem() {
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = "BK"
            item.button?.font = .menuBarFont(ofSize: 13)
            item.button?.toolTip = "Keyboard Brightness Keys"
            item.menu = menu
            statusItem = item
        }
        statusItem?.isVisible = true
        rebuildMenu()
    }

    private func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private func rebuildMenu() {
        menu.removeAllItems()
        menu.autoenablesItems = false

        let state = Config.enabled ? "On — keyboard backlight" : "Paused"
        menu.addItem(disabled("Keyboard Brightness Keys"))
        menu.addItem(disabled(state))
        menu.addItem(.separator())
        menu.addItem(item("Open Settings…", #selector(openSettings)))
        menu.addItem(.separator())
        menu.addItem(item("Hide Menu Icon", #selector(hideIcon)))
        menu.addItem(disabled("Open Settings app to show it again"))
        menu.addItem(.separator())
        let quit = item("Quit Helper", #selector(quit))
        quit.keyEquivalent = "q"
        menu.addItem(quit)
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func item(_ title: String, _ sel: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: sel, keyEquivalent: "")
        item.target = self
        item.isEnabled = true
        return item
    }

    @objc private func openSettings() { HelperControl.openSettings() }

    @objc private func hideIcon() {
        Config.menuIconVisible = false
        removeStatusItem()
    }

    @objc private func quit() { NSApp.terminate(nil) }
}
