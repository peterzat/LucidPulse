import Foundation
import Combine
import WatchKit // Required for WKInterfaceDevice and haptics

/// Represents the available time intervals for reminders.
enum ReminderInterval: String, CaseIterable, Identifiable {
    #if DEBUG
    case oneMinute = "10 Seconds (Debug)"
    #endif
    case fifteenMinutes = "15 Minutes"
    case thirtyMinutes = "30 Minutes"
    case oneHour = "1 Hour"
    case twoHours = "2 Hours"

    var id: String { self.rawValue }

    /// Returns the time interval in seconds.
    var timeInterval: TimeInterval {
        switch self {
        #if DEBUG
        case .oneMinute: return 10
        #endif
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 120 * 60
        }
    }
}

/// Represents the available haptic patterns for reminders.
enum HapticPattern: String, CaseIterable, Identifiable {
    case fiveLong = "Long Pulses"
    case eightShort = "Short Pulses"
    case longPauseLong = "Pulse, Pause, Pulse"

    var id: String { self.rawValue }
}

/// Manages the application's settings and state.
class SettingsViewModel: ObservableObject {
    /// Key for UserDefaults storage.
    private enum Keys {
        static let isReminderActive = "isReminderActive"
        static let selectedInterval = "selectedInterval"
        static let selectedPattern = "selectedPattern"
    }

    /// Whether the haptic reminders are currently active.
    @Published var isReminderActive: Bool {
        didSet {
            UserDefaults.standard.set(isReminderActive, forKey: Keys.isReminderActive)
            // Scheduling is now handled by the App struct based on state changes and lifecycle
            print("Reminder Active state changed: \(isReminderActive)")
        }
    }

    /// The user-selected time interval for reminders.
    @Published var selectedInterval: ReminderInterval {
        didSet {
            UserDefaults.standard.set(selectedInterval.rawValue, forKey: Keys.selectedInterval)
             // Scheduling is now handled by the App struct based on state changes and lifecycle
             print("Reminder Interval changed: \(selectedInterval.rawValue)")
        }
    }

    /// The user-selected haptic pattern for reminders.
    @Published var selectedPattern: HapticPattern {
        didSet {
            UserDefaults.standard.set(selectedPattern.rawValue, forKey: Keys.selectedPattern)
             print("Haptic Pattern changed: \(selectedPattern.rawValue)")
            // We don't need to reschedule for pattern changes, just use the new one next time.
        }
    }

    init() {
        // Load saved settings or defaults
        self.isReminderActive = UserDefaults.standard.bool(forKey: Keys.isReminderActive) // Defaults to false
        self.selectedInterval = ReminderInterval(rawValue: UserDefaults.standard.string(forKey: Keys.selectedInterval) ?? ReminderInterval.oneMinute.rawValue) ?? .oneMinute
        self.selectedPattern = HapticPattern(rawValue: UserDefaults.standard.string(forKey: Keys.selectedPattern) ?? HapticPattern.fiveLong.rawValue) ?? .fiveLong

        print("SettingsViewModel initialized:")
        print("- Reminder Active: \(self.isReminderActive)")
        print("- Selected Interval: \(self.selectedInterval.rawValue)")
        print("- Selected Pattern: \(self.selectedPattern.rawValue)")
    }

    // Placeholder for future telemetry integration
    func logReminderTriggered() {
        // Replace with actual analytics/logging call
        print("Telemetry: Reminder triggered with pattern \(selectedPattern.rawValue)")
    }

    // Removed scheduleNextReminder() as it's handled in LucidPulseApp.swift

    // Plays the currently selected haptic pattern.
    @MainActor // Ensure haptic playback happens on the main thread
    func playSelectedHaptic() async {
        print("Haptics: Playing pattern \(selectedPattern.rawValue)")

        let device = WKInterfaceDevice.current()
        let mediumPause: UInt64 = 800_000_000 // 0.8 seconds
        let longPause: UInt64 = 1200_000_000   // 1.2 seconds (increased from 0.8s)

        switch selectedPattern {
        case .fiveLong:
            print("Starting five long buzzes pattern")
            let pauseDuration: UInt64 = 1_000_000_000 // 1.0 second pause
            for i in 0..<5 {
                print("Attempting to play buzz \(i + 1) of 5")
                device.play(.notification)
                print("Played buzz \(i + 1). Pausing...")
                // Ensure the pause happens even if the haptic call is brief
                do {
                    try await Task.sleep(nanoseconds: pauseDuration)
                } catch {
                    print("Sleep interrupted: \(error)")
                    // Decide how to handle interruption, maybe break or continue?
                    break // Exit loop if sleep is interrupted
                }
                print("Pause complete after buzz \(i + 1)")
            }
            print("Finished five long buzzes pattern")

        case .eightShort:
            print("Starting eight short buzzes pattern")
            for i in 0..<8 {
                print("Playing buzz \(i + 1) of 8")
                device.play(.success)
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds between each buzz
            }
            print("Finished eight short buzzes pattern")

        case .longPauseLong:
            print("Starting long pause long pattern")
            // First long buzz
            device.play(.notification)
            try? await Task.sleep(nanoseconds: longPause)
            // Second long buzz
            device.play(.notification)
            print("Finished long pause long pattern")
        }

        // Log the event after the pattern finishes playing
        logReminderTriggered()
    }
} 
