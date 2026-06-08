import Foundation

/// Mach service the privileged helper registers and the app connects to.
let helperMachServiceName = "com.gigaptera.modafinil.helper"

@objc protocol HelperProtocol {
    /// Toggle the system-wide `SleepDisabled` flag (`pmset -a disablesleep`).
    /// This is the only thing that survives closing the lid — IOPMAssertion and
    /// caffeinate do not override clamshell sleep.
    func setDisableSleep(_ enabled: Bool, withReply reply: @escaping (Bool) -> Void)
}
