import Cocoa

enum MediaKey {
    static let illuminationUp: Int32 = 21
    static let illuminationDown: Int32 = 22

    private static let auxSubtype: Int16 = 8

    static func postKeyboardBrightness(dimming: Bool) {
        let key = dimming ? illuminationDown : illuminationUp
        post(key, down: true)
        post(key, down: false)
    }

    private static func post(_ key: Int32, down: Bool) {
        let flag = down ? 0xA : 0xB
        let data1 = (Int(key) << 16) | (flag << 8)
        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flag << 8)),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: auxSubtype,
            data1: data1,
            data2: -1
        ) else { return }
        event.cgEvent?.post(tap: .cghidEventTap)
    }
}
