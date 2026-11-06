import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = SettingsAppDelegate()
app.delegate = delegate
app.run()

final class SettingsAppDelegate: NSObject, NSApplicationDelegate {
    private var window: SettingsWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isDuplicateInstance {
            DistributedNotificationCenter.default().postNotificationName(
                AppIdentity.Note.openSettings,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NSApp.terminate(nil)
            }
            return
        }

        _ = HelperControl.ensureRunning()

        let window = SettingsWindow()
        self.window = window
        window.show()

        DistributedNotificationCenter.default().addObserver(
            forName: AppIdentity.Note.openSettings,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.window?.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window?.show()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private var isDuplicateInstance: Bool {
        NSRunningApplication.runningApplications(withBundleIdentifier: AppIdentity.settingsID)
            .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
    }
}

final class SettingsWindow: NSWindowController {
    private let helperLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let enabledButton = NSButton(
        checkboxWithTitle: "Enabled (F5 dims, F6 brightens keyboard)",
        target: nil,
        action: nil
    )
    private let iconButton = NSButton(
        checkboxWithTitle: "Show icon in menu bar",
        target: nil,
        action: nil
    )
    private let loginButton = NSButton(
        checkboxWithTitle: "Start helper at login",
        target: nil,
        action: nil
    )
    private var statusTimer: Timer?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 280),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = AppIdentity.name
        window.center()
        window.isReleasedWhenClosed = false
        super.init(window: window)
        buildUI()
        refresh()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshHelperStatus()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    deinit {
        statusTimer?.invalidate()
    }

    func show() {
        refresh()
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildUI() {
        guard let content = window?.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 12
        root.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            root.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            root.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -20),
        ])

        let title = NSTextField(labelWithString: AppIdentity.name)
        title.font = .systemFont(ofSize: 17, weight: .semibold)
        root.addArrangedSubview(title)

        helperLabel.font = .systemFont(ofSize: 12)
        root.addArrangedSubview(helperLabel)

        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        root.addArrangedSubview(statusLabel)

        enabledButton.target = self
        enabledButton.action = #selector(toggleEnabled)
        root.addArrangedSubview(enabledButton)

        iconButton.target = self
        iconButton.action = #selector(toggleIcon)
        root.addArrangedSubview(iconButton)

        loginButton.target = self
        loginButton.action = #selector(toggleLogin)
        root.addArrangedSubview(loginButton)

        let helperRow = NSStackView(views: [
            NSButton(title: "Start Helper", target: self, action: #selector(startHelper)),
            NSButton(title: "Stop Helper", target: self, action: #selector(stopHelper)),
        ])
        helperRow.orientation = .horizontal
        helperRow.spacing = 8
        root.addArrangedSubview(helperRow)

        root.addArrangedSubview(tip("The helper has no Dock icon."))
        root.addArrangedSubview(tip("This Settings app is only for configuration — quit it anytime; the helper keeps working."))
    }

    private func tip(_ text: String) -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: text)
        field.font = .systemFont(ofSize: 11)
        field.textColor = .secondaryLabelColor
        field.preferredMaxLayoutWidth = 380
        return field
    }

    private func refresh() {
        refreshHelperStatus()
        statusLabel.stringValue = Config.enabled
            ? "Keys: F5 dims keyboard backlight, F6 brightens"
            : "Keys: paused"
        enabledButton.state = Config.enabled ? .on : .off
        iconButton.state = Config.menuIconVisible ? .on : .off
        loginButton.state = LoginItem.isEnabled ? .on : .off
    }

    private func refreshHelperStatus() {
        if HelperControl.isRunning {
            helperLabel.stringValue = "Helper: running"
            helperLabel.textColor = .systemGreen
        } else {
            helperLabel.stringValue = "Helper: not running"
            helperLabel.textColor = .systemRed
        }
    }

    @objc private func toggleEnabled() {
        Config.enabled = enabledButton.state == .on
        refresh()
    }

    @objc private func toggleIcon() {
        Config.menuIconVisible = iconButton.state == .on
        refresh()
    }

    @objc private func startHelper() {
        _ = HelperControl.ensureRunning()
        Config.notify()
        refresh()
    }

    @objc private func stopHelper() {
        HelperControl.quit()
        refresh()
    }

    @objc private func toggleLogin() {
        do {
            try LoginItem.setEnabled(loginButton.state == .on)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn’t set login item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        refresh()
    }
}
