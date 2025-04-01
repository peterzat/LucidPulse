//
//  LucidPulseApp.swift
//  LucidPulse Watch App
//
//  Created by Peter Zatloukal on 3/31/25.
//

import SwiftUI
#if canImport(BackgroundTasks)
import BackgroundTasks // Import the BackgroundTasks framework
#endif

// Define a unique identifier for the background task
let backgroundTaskIdentifier = "com.yourdomain.LucidPulse.reminderTask" // Replace with your actual domain

@main
struct LucidPulse_Watch_AppApp: App {
    // Keep a reference to the ViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()

    // Scene phase helps manage app lifecycle events
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                 // Pass the ViewModel to the ContentView
                 .environmentObject(settingsViewModel)
        }
        #if canImport(BackgroundTasks)
        // Register the background task handler when the app launches
        .backgroundTask(.appRefresh(backgroundTaskIdentifier)) {
             await handleAppRefresh()
        }
        #endif
        // Monitor scene phase changes
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Schedule the next reminder when the app moves to the background
                #if canImport(BackgroundTasks)
                scheduleAppRefresh()
                #else
                // BackgroundTasks not available on simulator
                print("Simulator: Background scheduling skipped.")
                #endif
            }
        }
    }

    /// Function to schedule the background app refresh task.
    func scheduleAppRefresh() {
        #if canImport(BackgroundTasks)
        // Ensure reminders are active before scheduling
        guard settingsViewModel.isReminderActive else {
            print("Background Task: Reminders are disabled, cancelling existing tasks.")
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        // Set the earliest begin date based on the selected interval
        request.earliestBeginDate = Date(timeIntervalSinceNow: settingsViewModel.selectedInterval.timeInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background Task: Scheduled app refresh for \(request.earliestBeginDate?.description ?? "immediately")")
        } catch {
            print("Background Task: Could not schedule app refresh: \(error)")
        }
        #else
        // BackgroundTasks not available on simulator
        print("Simulator: scheduleAppRefresh called, but BackgroundTasks not available.")
        #endif
    }

    /// Function to handle the background task when it executes.
    func handleAppRefresh() async {
        #if canImport(BackgroundTasks)
        // Schedule the next refresh immediately to keep the chain going
        scheduleAppRefresh()

        // Perform the haptic playback
        print("Background Task: Handling app refresh - Playing haptic.")
        await Task { // Perform UI related tasks on main actor
             settingsViewModel.playSelectedHaptic()
        }.value

        // Log the event (using the ViewModel's telemetry placeholder)
        await Task {
             settingsViewModel.logReminderTriggered()
        }.value
        #else
        // This should theoretically not be called on simulator as the handler isn't registered
        print("Simulator: handleAppRefresh called unexpectedly.")
        #endif
    }
}
