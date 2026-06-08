import Foundation
import ServiceManagement

/// Manages the privileged helper (root LaunchDaemon) that toggles `pmset disablesleep`.
/// All methods are expected to be called on the main thread.
final class HelperManager {
    static let shared = HelperManager()

    private let plistName = "com.gigaptera.modafinil.helper.plist"
    private var connection: NSXPCConnection?

    private var service: SMAppService { SMAppService.daemon(plistName: plistName) }

    var status: SMAppService.Status { service.status }
    var isEnabled: Bool { service.status == .enabled }

    /// Clears any stale `disablesleep` flag left by a previous crash — the app always starts
    /// inactive, so it is safe to force it off. Does NOT register: registration is opt-in via
    /// the menu, so first-run users don't get an unexpected background-item approval prompt.
    func cleanUpOnLaunch() {
        if isEnabled { setDisableSleep(false) }
    }

    /// User-initiated enable. Opens Login Items settings when approval is still pending.
    @discardableResult
    func register() -> SMAppService.Status {
        try? service.register()
        if service.status == .requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        return service.status
    }

    func unregister() {
        try? service.unregister()
        connection?.invalidate()
        connection = nil
    }

    func setDisableSleep(_ enabled: Bool, completion: ((Bool) -> Void)? = nil) {
        guard isEnabled else { completion?(false); return }
        let proxy = makeConnection().remoteObjectProxyWithErrorHandler { _ in
            DispatchQueue.main.async { completion?(false) }
        }
        (proxy as? HelperProtocol)?.setDisableSleep(enabled) { ok in
            DispatchQueue.main.async { completion?(ok) }
        }
    }

    private func makeConnection() -> NSXPCConnection {
        if let connection { return connection }
        let c = NSXPCConnection(machServiceName: helperMachServiceName, options: .privileged)
        c.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        c.invalidationHandler = { [weak self] in
            DispatchQueue.main.async { self?.connection = nil }
        }
        c.resume()
        connection = c
        return c
    }
}
