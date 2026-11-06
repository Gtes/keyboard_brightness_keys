import Foundation

enum AppIdentity {
    static let name = "Keyboard Brightness Keys"
    static let helperName = "Keyboard Brightness Keys Helper"

    static let settingsID = "com.keyboardbrightnesskeys.settings"
    static let helperID = "com.keyboardbrightnesskeys.helper"
    static let prefsID = "com.keyboardbrightnesskeys"

    static let settingsFile = "\(name).app"
    static let helperFile = "\(helperName).app"

    enum Note {
        static let configChanged = Notification.Name("com.keyboardbrightnesskeys.configChanged")
        static let quitHelper = Notification.Name("com.keyboardbrightnesskeys.quitHelper")
        static let openSettings = Notification.Name("com.keyboardbrightnesskeys.openSettings")
    }
}
