import Foundation
import IOKit.pwr_mgt

/// Simple localization helper (no .strings / lproj needed).
/// English is default. Japanese strings are used *only* when system locale is Japanese (ja).
enum L {
    static func string(_ key: String, _ args: CVarArg...) -> String {
        // Respect the user's preferred languages from System Settings.
        // This works even for apps without .lproj resources (unlike Locale.current in some cases).
        let useJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") ?? false

        let strings = useJapanese ? ja : en
        guard let format = strings[key] else {
            return key
        }
        if args.isEmpty {
            return format
        }
        return String(format: format, arguments: args)
    }

    private static let en: [String: String] = [
        "duration_30m": "30 min",
        "duration_1h": "1 hour",
        "duration_2h": "2 hours",
        "duration_4h": "4 hours",
        "duration_unlimited": "Unlimited",

        "stop": "Stop",
        "remaining_m": "%d min left",
        "remaining_hm": "%dh %dm left",

        "lid_enable": "Keep awake with lid closed…",
        "lid_approve": "Approve helper in Settings…",
        "lid_on": "Awake with lid closed",

        "launch_at_login": "Launch at login",
        "quit": "Quit Modafinil",
    ]

    private static let ja: [String: String] = [
        "duration_30m": "30分",
        "duration_1h": "1時間",
        "duration_2h": "2時間",
        "duration_4h": "4時間",
        "duration_unlimited": "無制限",

        "stop": "停止",
        "remaining_m": "残り %d 分",
        "remaining_hm": "残り %d時間%d分",

        "lid_enable": "フタを閉じても継続…",
        "lid_approve": "設定でヘルパーを承認…",
        "lid_on": "フタを閉じても継続",

        "launch_at_login": "ログイン時に起動",
        "quit": "Modafinil を終了",
    ]
}

enum SleepDuration: String, CaseIterable {
    case thirtyMinutes = "30m"
    case oneHour       = "1h"
    case twoHours      = "2h"
    case fourHours     = "4h"
    case unlimited     = "unlimited"

    var seconds: TimeInterval? {
        switch self {
        case .thirtyMinutes: return 1800
        case .oneHour:       return 3600
        case .twoHours:      return 7200
        case .fourHours:     return 14400
        case .unlimited:     return nil
        }
    }

    var label: String {
        switch self {
        case .thirtyMinutes: return L.string("duration_30m")
        case .oneHour:       return L.string("duration_1h")
        case .twoHours:      return L.string("duration_2h")
        case .fourHours:     return L.string("duration_4h")
        case .unlimited:     return L.string("duration_unlimited")
        }
    }
}

@Observable
final class SleepPreventer {
    private(set) var isActive = false
    private var systemAssertionID: IOPMAssertionID = 0
    private var idleAssertionID: IOPMAssertionID = 0
    private var displayAssertionID: IOPMAssertionID = 0   // for preventing display sleep / auto-lock
    private var timer: Timer?

    var remainingTime: TimeInterval? {
        guard isActive, let fireDate = timer?.fireDate else { return nil }
        return max(0, fireDate.timeIntervalSinceNow)
    }

    func toggle(duration: TimeInterval?) {
        isActive ? deactivate() : activate(duration: duration)
    }

    func activate(duration: TimeInterval?) {
        // Use proper typed constants (more robust than string literals).
        // PreventSystemSleep is the primary one (what Amphetamine-style tools rely on).
        let sysResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Modafinil: preventing system sleep" as CFString,
            &systemAssertionID
        )

        // Secondary system idle assertion.
        _ = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Modafinil: preventing idle sleep" as CFString,
            &idleAssertionID
        )

        // Display sleep prevention (helps keep lock from triggering on lid close).
        _ = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Modafinil: preventing display sleep / lock" as CFString,
            &displayAssertionID
        )

        guard sysResult == kIOReturnSuccess else { return }

        isActive = true

        // Lid-closed (clamshell) sleep is only prevented by `pmset disablesleep`, which needs
        // root — delegated to the privileged helper. No-op if the helper isn't enabled yet.
        HelperManager.shared.setDisableSleep(true)

        if let d = duration {
            timer = Timer.scheduledTimer(withTimeInterval: d, repeats: false) { [weak self] _ in
                self?.deactivate()
            }
        }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil

        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }
        if idleAssertionID != 0 {
            IOPMAssertionRelease(idleAssertionID)
            idleAssertionID = 0
        }
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }

        HelperManager.shared.setDisableSleep(false)

        isActive = false
    }
}
