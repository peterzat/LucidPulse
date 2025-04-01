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
    private var isPlayingHaptics = false
    var hapticViewModel: SettingsViewModel?
    
    override init() {
        super.init()
        print("ExtendedRuntimeSessionManager initialized")
    }
    
    func scheduleNextSession(interval: TimeInterval) {
        print("Scheduling next session with interval: \(interval) seconds")
        
        // Don't schedule if we're already playing haptics
        guard !isPlayingHaptics else {
            print("Already playing haptics, skipping new schedule")
            return
        }
        
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
        isPlayingHaptics = false
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
            
            if timeUntilNext <= 5 && self.currentSession == nil && !self.isPlayingHaptics {
                print("Starting extended runtime session")
                self.startExtendedRuntimeSession()
            }
        }
    }
    
    private func startExtendedRuntimeSession() {
        guard currentSession == nil && !isPlayingHaptics else {
            print("Session already exists or haptics playing, not starting new one")
            return
        }
        
        print("Creating new extended runtime session")
        
        // Create the session
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        currentSession = session
        
        // Start haptic sequence immediately
        Task { @MainActor in
            print("Starting haptic sequence in background task")
            do {
                try await playHapticSequence()
            } catch {
                print("Error playing haptic sequence: \(error)")
                self.invalidateCurrentSession()
            }
        }
    }
    
    private func playHapticSequence() async throws {
        guard let viewModel = hapticViewModel else {
            print("No haptic view model available")
            return
        }
        
        isPlayingHaptics = true
        print("Playing haptic sequence")
        
        // Play the haptic pattern once
        print("Playing haptic pattern")
        await viewModel.playSelectedHaptic()
        print("Completed haptic pattern")
        
        // Add a small delay before scheduling next session
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Reset state before scheduling next session
        isPlayingHaptics = false
        
        // Schedule next session
        if viewModel.isReminderActive {
            print("Scheduling next session after haptic sequence")
            scheduleNextSession(interval: viewModel.selectedInterval.timeInterval)
        } else {
            print("Reminders no longer active, not scheduling next session")
        }
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        print("Session invalidated with reason: \(reason), error: \(String(describing: error))")
        DispatchQueue.main.async {
            self.currentSession = nil
            // Only restart monitoring if we're not currently playing haptics
            if self.nextScheduledDate != nil && !self.isPlayingHaptics {
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
        // Only restart monitoring if we're not currently playing haptics
        if nextScheduledDate != nil && !isPlayingHaptics {
            print("Restarting monitoring before session expiration")
            startMonitoringTime()
        }
    }
}
