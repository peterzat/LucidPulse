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
    private var hapticViewModel: SettingsViewModel?
    
    override init() {
        super.init()
        startMonitoringTime()
    }
    
    func scheduleNextSession(interval: TimeInterval) {
        // Invalidate any existing session
        invalidateCurrentSession()
        
        // Calculate the next scheduled time
        nextScheduledDate = Date(timeIntervalSinceNow: interval)
        
        // Start monitoring for the next interval
        startMonitoringTime()
    }
    
    func invalidateCurrentSession() {
        currentSession?.invalidate()
        currentSession = nil
        nextScheduledDate = nil
    }
    
    private func startMonitoringTime() {
        // Create a timer to check every second if we need to start a session
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self,
                  let nextDate = self.nextScheduledDate else {
                timer.invalidate()
                return
            }
            
            let timeUntilNext = nextDate.timeIntervalSinceNow
            if timeUntilNext <= 5 { // Start session 5 seconds before needed
                self.startExtendedRuntimeSession()
                timer.invalidate()
            }
        }
    }
    
    private func startExtendedRuntimeSession() {
        guard currentSession == nil else { return }
        
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        currentSession = session
    }
    
    // MARK: - WKExtendedRuntimeSessionDelegate
    
    func extendedRuntimeSession(_ session: WKExtendedRuntimeSession, didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason, error: Error?) {
        DispatchQueue.main.async {
            self.currentSession = nil
            // If we still have a next scheduled date, start monitoring again
            if self.nextScheduledDate != nil {
                self.startMonitoringTime()
            }
        }
    }
    
    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        guard let nextDate = nextScheduledDate else { return }
        
        // Wait until the exact time to play the haptic
        let timeUntilNext = nextDate.timeIntervalSinceNow
        if timeUntilNext > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilNext) { [weak self] in
                guard let self = self,
                      session === self.currentSession,
                      session.state == .running else { return }
                
                // Play the haptic
                Task { @MainActor in
                    if let viewModel = self.hapticViewModel {
                        viewModel.playSelectedHaptic()
                    }
                }
                
                // Schedule the next session
                if let interval = self.hapticViewModel?.selectedInterval.timeInterval {
                    self.scheduleNextSession(interval: interval)
                }
            }
        }
    }
    
    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        // Session is about to expire, schedule the next one if needed
        if nextScheduledDate != nil {
            startMonitoringTime()
        }
    }
}
