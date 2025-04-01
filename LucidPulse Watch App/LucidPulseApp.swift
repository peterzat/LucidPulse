//
//  LucidPulseApp.swift
//  LucidPulse Watch App
//
//  Created by Peter Zatloukal on 3/31/25.
//

import SwiftUI
import WatchKit

@main
struct LucidPulse_Watch_AppApp: App {
    // Keep a reference to the ViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    // Scene phase helps manage app lifecycle events
    @Environment(\.scenePhase) private var scenePhase
    
    // Create a session manager to handle background tasks
    @StateObject private var sessionManager = ExtendedRuntimeSessionManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsViewModel)
                .onAppear {
                    sessionManager.hapticViewModel = settingsViewModel
                    if settingsViewModel.isReminderActive {
                        sessionManager.scheduleNextSession(interval: settingsViewModel.selectedInterval.timeInterval)
                    }
                }
                .onChange(of: settingsViewModel.isReminderActive) { _, isActive in
                    if isActive {
                        sessionManager.scheduleNextSession(interval: settingsViewModel.selectedInterval.timeInterval)
                    } else {
                        sessionManager.invalidateCurrentSession()
                    }
                }
                .onChange(of: settingsViewModel.selectedInterval) { _, newInterval in
                    if settingsViewModel.isReminderActive {
                        sessionManager.scheduleNextSession(interval: newInterval.timeInterval)
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                if settingsViewModel.isReminderActive {
                    sessionManager.scheduleNextSession(interval: settingsViewModel.selectedInterval.timeInterval)
                }
            case .background:
                // No need to do anything special when going to background
                break
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }
}

class ExtendedRuntimeSessionManager: NSObject, ObservableObject, WKExtendedRuntimeSessionDelegate {
    private var currentSession: WKExtendedRuntimeSession?
    private var nextScheduledDate: Date?
    private var monitoringTimer: Timer?
    private var hapticPlaybackTimer: Timer?
    private var remainingHaptics: Int = 0
    var hapticViewModel: SettingsViewModel?
    
    override init() {
        super.init()
        print("ExtendedRuntimeSessionManager initialized")
    }
    
    func scheduleNextSession(interval: TimeInterval) {
        print("Scheduling next session with interval: \(interval) seconds")
        
        // Invalidate any existing session
        invalidateCurrentSession()
        
        // Calculate the next scheduled time
        nextScheduledDate = Date(timeIntervalSinceNow: interval)
        if let date = nextScheduledDate {
            print("Next haptic scheduled for: \(date)")
        }
        
        // Start monitoring for the next interval
        startMonitoringTime()
    }
    
    func invalidateCurrentSession() {
        print("Invalidating current session")
        currentSession?.invalidate()
        currentSession = nil
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        hapticPlaybackTimer?.invalidate()
        hapticPlaybackTimer = nil
        remainingHaptics = 0
    }
    
    private func startMonitoringTime() {
        // Invalidate existing timer if any
        monitoringTimer?.invalidate()
        
        // Create a timer to check every second if we need to start a session
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self,
                  let nextDate = self.nextScheduledDate else {
                print("No next date scheduled, stopping timer")
                timer.invalidate()
                return
            }
            
            let timeUntilNext = nextDate.timeIntervalSinceNow
            print("Time until next haptic: \(timeUntilNext) seconds")
            
            if timeUntilNext <= 5 && self.currentSession == nil { // Start session 5 seconds before needed
                print("Starting extended runtime session")
                self.startExtendedRuntimeSession()
            }
        }
    }
    
    private func startExtendedRuntimeSession() {
        guard currentSession == nil else {
            print("Session already exists, not starting new one")
            return
        }
        
        print("Creating new extended runtime session")
        
        // Create the session
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        currentSession = session
        
        // Start haptic sequence immediately
        startHapticSequence()
    }
    
    private func startHapticSequence() {
        guard let viewModel = hapticViewModel else {
            print("No haptic view model available")
            return
        }
        
        // Set up the haptic sequence
        remainingHaptics = 5 // Number of haptics in the sequence
        print("Starting haptic sequence with \(remainingHaptics) haptics")
        
        // Play first haptic immediately
        playNextHaptic()
        
        // Schedule remaining haptics
        hapticPlaybackTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.playNextHaptic()
        }
    }
    
    private func playNextHaptic() {
        guard let viewModel = hapticViewModel else {
            print("No haptic view model available")
            return
        }
        
        guard remainingHaptics > 0 else {
            print("Haptic sequence complete")
            hapticPlaybackTimer?.invalidate()
            hapticPlaybackTimer = nil
            
            // Schedule next session
            if viewModel.isReminderActive {
                print("Scheduling next session after haptic sequence")
                scheduleNextSession(interval: viewModel.selectedInterval.timeInterval)
            } else {
                print("Reminders no longer active, not scheduling next session")
            }
            return
        }
        
        print("Playing haptic \(6 - remainingHaptics) of 5")
        Task { @MainActor in
            viewModel.playSelectedHaptic()
            remainingHaptics -= 1
        }
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Session invalidated with reason: \(reason), error: \(String(describing: error))")
        DispatchQueue.main.async {
            self.currentSession = nil
            // If we still have a next scheduled date, start monitoring again
            if self.nextScheduledDate != nil {
                print("Restarting monitoring after session invalidation")
                self.startMonitoringTime()
            }
        }
    }
    
    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("Extended runtime session did start")
    }
    
    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("Session will expire")
        // Start monitoring for the next session before this one expires
        if nextScheduledDate != nil {
            print("Restarting monitoring before session expiration")
            startMonitoringTime()
        }
    }
}
