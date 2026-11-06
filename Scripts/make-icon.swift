import Cocoa

let destination = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.icns")
let iconset = destination.deletingLastPathComponent().appendingPathComponent("AppIcon.iconset")

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

for (size, name) in sizes {
    try png(size: size).write(to: iconset.appendingPathComponent(name))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", destination.path]
try iconutil.run()
iconutil.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
if iconutil.terminationStatus != 0 { exit(iconutil.terminationStatus) }

func png(size: Int) -> Data {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()
    let amber = NSColor(calibratedRed: 0.98, green: 0.62, blue: 0.12, alpha: 1)
    amber.setFill(); amber.setStroke()
    let side = CGFloat(size)
    let center = NSPoint(x: side / 2, y: side / 2)
    let disk = side * 0.20
    NSBezierPath(ovalIn: NSRect(x: center.x - disk, y: center.y - disk, width: disk * 2, height: disk * 2)).fill()
    let rays = NSBezierPath()
    rays.lineWidth = max(1, side * 0.055)
    rays.lineCapStyle = .round
    for index in 0..<8 {
        let angle = (CGFloat(index) / 8) * .pi * 2 - .pi / 2
        rays.move(to: NSPoint(x: center.x + cos(angle) * side * 0.30, y: center.y + sin(angle) * side * 0.30))
        rays.line(to: NSPoint(x: center.x + cos(angle) * side * 0.44, y: center.y + sin(angle) * side * 0.44))
    }
    rays.stroke()
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
