import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let preventer = SleepPreventer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        button.image = .pillOff
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self

        HelperManager.shared.cleanUpOnLaunch()
        observeActive()
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMenu(sender)
        } else {
            let dur = (SleepDuration(rawValue: UserDefaults.standard.string(forKey: "duration") ?? "") ?? .unlimited).seconds
            preventer.toggle(duration: dur)
        }
    }

    private func showMenu(_ sender: NSStatusBarButton) {
        // Helper approval is async with no completion callback, so the helper can become
        // enabled after prevention is already on, leaving SleepDisabled unset. Reconcile the
        // flag to the current prevention state on every menu open (no-op while not enabled).
        HelperManager.shared.setDisableSleep(preventer.isActive)

        let menu = NSMenu()

        if preventer.isActive {
            if let rem = preventer.remainingTime {
                let h = Int(rem) / 3600
                let m = Int(rem) % 3600 / 60
                let title = h > 0
                    ? L.string("remaining_hm", h, m)
                    : L.string("remaining_m", m)
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
            menu.addItem(NSMenuItem(title: L.string("stop"), action: #selector(stop), keyEquivalent: ""))
            menu.addItem(.separator())
        }

        let current = SleepDuration(rawValue: UserDefaults.standard.string(forKey: "duration") ?? "") ?? .unlimited
        for d in SleepDuration.allCases {
            let item = NSMenuItem(title: d.label, action: #selector(selectDuration(_:)), keyEquivalent: "")
            item.representedObject = d.rawValue
            item.state = d == current ? .on : .off
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(lidModeItem())

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: L.string("launch_at_login"), action: #selector(toggleLogin), keyEquivalent: "")
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: L.string("quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }

    private func lidModeItem() -> NSMenuItem {
        switch HelperManager.shared.status {
        case .enabled:
            let item = NSMenuItem(title: L.string("lid_on"), action: #selector(disableLidMode), keyEquivalent: "")
            item.state = .on
            return item
        case .requiresApproval:
            return NSMenuItem(title: L.string("lid_approve"), action: #selector(enableLidMode), keyEquivalent: "")
        default:
            return NSMenuItem(title: L.string("lid_enable"), action: #selector(enableLidMode), keyEquivalent: "")
        }
    }

    @objc private func enableLidMode() {
        if HelperManager.shared.register() == .enabled, preventer.isActive {
            HelperManager.shared.setDisableSleep(true)
        }
    }

    @objc private func disableLidMode() {
        HelperManager.shared.setDisableSleep(false)
        HelperManager.shared.unregister()
    }

    @objc private func stop() { preventer.deactivate() }

    @objc private func selectDuration(_ item: NSMenuItem) {
        guard let raw = item.representedObject as? String else { return }
        UserDefaults.standard.set(raw, forKey: "duration")
    }

    @objc private func toggleLogin() {
        let svc = SMAppService.mainApp
        try? svc.status == .enabled ? svc.unregister() : svc.register()
    }

    private func observeActive() {
        withObservationTracking {
            _ = preventer.isActive
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateIcon()
                self?.observeActive()
            }
        }
    }

    private func updateIcon() {
        statusItem?.button?.image = preventer.isActive ? .pillOn : .pillOff
    }

    // Ensure assertions are released and disablesleep reverted if user quits while active
    func applicationWillTerminate(_ notification: Notification) {
        if preventer.isActive {
            preventer.deactivate()
        }
    }
}
