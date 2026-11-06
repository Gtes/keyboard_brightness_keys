import Foundation

enum AppID {
    static let helper = "com.fkeysremap.brightnesskeys.helper"
    static let settings = "com.fkeysremap.brightnesskeys.settings"
    static let prefs = "com.fkeysremap.brightnesskeys"
}

enum Note {
    static let configChanged = Notification.Name("com.fkeysremap.brightnesskeys.configChanged")
    static let showMenuIcon = Notification.Name("com.fkeysremap.brightnesskeys.showMenuIcon")
    static let quitHelper = Notification.Name("com.fkeysremap.brightnesskeys.quitHelper")
    static let openSettings = Notification.Name("com.fkeysremap.brightnesskeys.openSettings")
}

enum Config {
    private static let enabledKey = "enabled"
    private static let menuIconKey = "menuIconVisible"

    static var enabled: Bool {
        get { bool(enabledKey, default: true) }
        set { set(newValue, for: enabledKey); ping() }
    }

    static var menuIconVisible: Bool {
        get { bool(menuIconKey, default: true) }
        set { set(newValue, for: menuIconKey); ping(Note.showMenuIcon) }
    }

    static func ping(_ name: Notification.Name = Note.configChanged) {
        CFPreferencesAppSynchronize(AppID.prefs as CFString)
        DistributedNotificationCenter.default().postNotificationName(
            name,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private static func bool(_ key: String, default fallback: Bool) -> Bool {
        let value = CFPreferencesCopyAppValue(key as CFString, AppID.prefs as CFString)
        if let number = value as? Bool { return number }
        if let number = value as? NSNumber { return number.boolValue }
        return fallback
    }

    private static func set(_ value: Any, for key: String) {
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList, AppID.prefs as CFString)
        CFPreferencesAppSynchronize(AppID.prefs as CFString)
    }
}
