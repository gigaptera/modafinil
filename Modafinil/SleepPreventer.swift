import Foundation
import IOKit.pwr_mgt

enum SleepDuration: String, CaseIterable {
    case oneHour   = "1h"
    case twoHours  = "2h"
    case fourHours = "4h"
    case unlimited = "unlimited"

    var seconds: TimeInterval? {
        switch self {
        case .oneHour:   return 3600
        case .twoHours:  return 7200
        case .fourHours: return 14400
        case .unlimited: return nil
        }
    }

    var label: String {
        switch self {
        case .oneHour:   return "1時間"
        case .twoHours:  return "2時間"
        case .fourHours: return "4時間"
        case .unlimited: return "無制限"
        }
    }
}

@Observable
final class SleepPreventer {
    private(set) var isActive = false
    private var assertionID: IOPMAssertionID = 0
    private var timer: Timer?

    var remainingTime: TimeInterval? {
        guard isActive, let fireDate = timer?.fireDate else { return nil }
        return max(0, fireDate.timeIntervalSinceNow)
    }

    func toggle(duration: TimeInterval?) {
        isActive ? deactivate() : activate(duration: duration)
    }

    func activate(duration: TimeInterval?) {
        let result = IOPMAssertionCreateWithName(
            "PreventSystemSleep" as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Modafinil: preventing sleep" as CFString,
            &assertionID
        )
        guard result == kIOReturnSuccess else { return }
        isActive = true

        if let d = duration {
            timer = Timer.scheduledTimer(withTimeInterval: d, repeats: false) { [weak self] _ in
                self?.deactivate()
            }
        }
    }

    func deactivate() {
        timer?.invalidate()
        timer = nil
        guard assertionID != 0 else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        isActive = false
    }
}
