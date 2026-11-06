import Foundation

enum Config {
    private static let enabledKey = "enabled"
    private static let menuIconKey = "menuIconVisible"

    static var enabled: Bool {
        get { bool(enabledKey, default: true) }
        set { set(newValue, for: enabledKey); notify() }
    }

    static var menuIconVisible: Bool {
        get { bool(menuIconKey, default: true) }
        set { set(newValue, for: menuIconKey); notify() }
    }

    static func notify() {
        CFPreferencesAppSynchronize(AppIdentity.prefsID as CFString)
        DistributedNotificationCenter.default().postNotificationName(
            AppIdentity.Note.configChanged,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private static func bool(_ key: String, default fallback: Bool) -> Bool {
        let value = CFPreferencesCopyAppValue(key as CFString, AppIdentity.prefsID as CFString)
        if let number = value as? Bool { return number }
        if let number = value as? NSNumber { return number.boolValue }
        return fallback
    }

    private static func set(_ value: Any, for key: String) {
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList, AppIdentity.prefsID as CFString)
        CFPreferencesAppSynchronize(AppIdentity.prefsID as CFString)
    }
}
