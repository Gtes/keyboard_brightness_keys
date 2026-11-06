import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = HelperAppDelegate()
app.delegate = delegate
app.run()

final class HelperAppDelegate: NSObject, NSApplicationDelegate {
    private let hid = HIDRemapper()
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private var activity: NSObjectProtocol?
    private var observers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isDuplicateInstance {
            NSApp.terminate(nil)
            return
        }

        activity = ProcessInfo.processInfo.beginActivity(
            options: .userInitiatedAllowingIdleSystemSleep,
            reason: AppIdentity.helperName
        )

        reload()
        observers = [
            DistributedNotificationCenter.default().addObserver(
                forName: AppIdentity.Note.configChanged, object: nil, queue: .main
            ) { [weak self] _ in self?.reload() },
            DistributedNotificationCenter.default().addObserver(
                forName: AppIdentity.Note.quitHelper, object: nil, queue: .main
            ) { _ in NSApp.terminate(nil) },
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
            ) { [weak self] _ in self?.reload() },
        ]
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        hid.syncAndWait(enabled: false)
        removeStatusItem()
    }

    private var isDuplicateInstance: Bool {
        NSRunningApplication.runningApplications(withBundleIdentifier: AppIdentity.helperID)
            .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    }

    private func reload() {
        hid.sync(enabled: Config.enabled)
        if Config.menuIconVisible {
            installStatusItem()
        } else {
            removeStatusItem()
        }
        rebuildMenu()
    }

    private func installStatusItem() {
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            guard let button = item.button else {
                NSStatusBar.system.removeStatusItem(item)
                return
            }
            button.title = ""
            button.image = Self.menuBarImage()
            button.imagePosition = .imageOnly
            button.toolTip = AppIdentity.name
            item.menu = menu
            statusItem = item
        }
        statusItem?.isVisible = true
    }

    private func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    private static func menuBarImage() -> NSImage {
        guard
            let url = Bundle.main.url(forResource: "Icon", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            preconditionFailure("Icon.png missing from helper bundle")
        }
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }

    private func rebuildMenu() {
        menu.removeAllItems()
        menu.autoenablesItems = false

        menu.addItem(label(AppIdentity.name))
        menu.addItem(label(Config.enabled ? "On — keyboard backlight" : "Paused"))
        menu.addItem(.separator())
        menu.addItem(action("Open Settings…", #selector(openSettings)))
        menu.addItem(.separator())
        menu.addItem(action("Hide Menu Icon", #selector(hideIcon)))
        menu.addItem(label("Open Settings to show it again"))
        menu.addItem(.separator())
        let quit = action("Quit", #selector(quit))
        quit.keyEquivalent = "q"
        menu.addItem(quit)
    }

    private func label(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func action(_ title: String, _ selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        item.isEnabled = true
        return item
    }

    @objc private func openSettings() {
        HelperControl.openSettings()
    }

    @objc private func hideIcon() {
        Config.menuIconVisible = false
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
