import Foundation

enum Shell {
    struct Result {
        var status: Int32
        var text: String
    }

    @discardableResult
    static func run(_ path: String, _ arguments: [String]) -> Result {
        let process = Process()
        let stdout = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return Result(status: 1, text: "")
        }
        process.waitUntilExit()
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        return Result(status: process.terminationStatus, text: String(data: data, encoding: .utf8) ?? "")
    }
}
