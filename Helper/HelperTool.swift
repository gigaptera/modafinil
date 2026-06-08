import Foundation

final class HelperTool: NSObject, HelperProtocol {
    func setDisableSleep(_ enabled: Bool, withReply reply: @escaping (Bool) -> Void) {
        reply(Self.runPmset(disable: enabled))
    }

    /// Runs as root (LaunchDaemon), so no sudo needed.
    @discardableResult
    static func runPmset(disable: Bool) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-a", "disablesleep", disable ? "1" : "0"]
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }
}
