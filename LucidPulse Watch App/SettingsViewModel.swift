import Foundation
import Combine
import WatchKit // Required for WKInterfaceDevice and haptics

/// Represents the available time intervals for reminders.
enum ReminderInterval: String, CaseIterable, Identifiable {
    case fifteenMinutes = "15 Minutes"
    case thirtyMinutes = "30 Minutes"
    case oneHour = "1 Hour"
    case twoHours = "2 Hours"

    var id: String { self.rawValue }

    /// Returns the time interval in seconds.
    var timeInterval: TimeInterval {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 120 * 60
        }
    }
}

/// Represents the available haptic patterns for reminders.
enum HapticPattern: String, CaseIterable, Identifiable {
    case fiveLong = "Five Long Buzzes"
    case longPauseShort = "Long, Pause, Short, Short, Short"
    case shortLongShort = "Short, Short, Short, Long, Long, Long, Short, Short, Short"

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
        self.selectedInterval = ReminderInterval(rawValue: UserDefaults.standard.string(forKey: Keys.selectedInterval) ?? ReminderInterval.oneHour.rawValue) ?? .oneHour
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
    func playSelectedHaptic() {
        print("Haptics: Playing pattern \(selectedPattern.rawValue)")

        // Use a Task for async operations like delays
        Task {
            let device = WKInterfaceDevice.current()
            let shortPause: UInt64 = 150_000_000 // 0.15 seconds in nanoseconds
            let mediumPause: UInt64 = 300_000_000 // 0.3 seconds
            let longPause: UInt64 = 500_000_000   // 0.5 seconds

            switch selectedPattern {
            case .fiveLong:
                for _ in 0..<5 {
                    device.play(.notification)
                    try? await Task.sleep(nanoseconds: mediumPause)
                }

            case .longPauseShort:
                // Long buzz
                device.play(.notification)
                try? await Task.sleep(nanoseconds: longPause)
                // Three short buzzes
                for _ in 0..<3 {
                    device.play(.click)
                    try? await Task.sleep(nanoseconds: shortPause)
                }

            case .shortLongShort:
                // First three short buzzes
                for _ in 0..<3 {
                    device.play(.click)
                    try? await Task.sleep(nanoseconds: shortPause)
                }
                try? await Task.sleep(nanoseconds: mediumPause)
                // Three long buzzes
                for _ in 0..<3 {
                    device.play(.notification)
                    try? await Task.sleep(nanoseconds: shortPause)
                }
                try? await Task.sleep(nanoseconds: mediumPause)
                // Final three short buzzes
                for _ in 0..<3 {
                    device.play(.click)
                    try? await Task.sleep(nanoseconds: shortPause)
                }
            }

            // Log the event after the pattern finishes playing
            logReminderTriggered()
        }
    }
} 