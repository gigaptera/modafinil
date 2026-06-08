import Foundation

final class HelperDelegate: NSObject, NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Only accept connections from our own signed app (bundle id + Team ID).
        newConnection.setCodeSigningRequirement(
            "identifier \"com.gigaptera.modafinil\" and anchor apple generic and certificate leaf[subject.OU] = \"DX295NS6CV\""
        )

        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = HelperTool()

        // Safety net: if the app quits or crashes while sleep is disabled, revert it.
        // `disablesleep` persists across reboots, so a lidded Mac in a bag would otherwise
        // never sleep — overheating and draining the battery.
        newConnection.invalidationHandler = {
            HelperTool.runPmset(disable: false)
        }

        newConnection.resume()
        return true
    }
}

let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: helperMachServiceName)
listener.delegate = delegate
listener.resume()
dispatchMain()
