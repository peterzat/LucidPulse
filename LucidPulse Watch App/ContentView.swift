//
//  ContentView.swift
//  LucidPulse Watch App
//
//  Created by Peter Zatloukal on 3/31/25.
//

import SwiftUI

struct ContentView: View {
    // Access the ViewModel from the environment
    @EnvironmentObject private var viewModel: SettingsViewModel

    var body: some View {
        NavigationView { // Use NavigationView for title and potential navigation
            Form { // Use Form for grouped settings controls
                Section(header: Text("Reminders")) {
                    // Toggle binding directly updates the ViewModel's @Published property
                    Toggle("Enable Reminders", isOn: $viewModel.isReminderActive)
                        // .onChange removed - scheduling is handled in LucidPulseApp based on state
                }

                // Only show interval/pattern pickers if reminders are enabled
                if viewModel.isReminderActive {
                    Section(header: Text("Configuration")) {
                        // Picker binding directly updates the ViewModel's @Published property
                        Picker("Interval", selection: $viewModel.selectedInterval) {
                            ForEach(ReminderInterval.allCases) { interval in
                                Text(interval.rawValue).tag(interval)
                            }
                        }
                         // .onChange removed - scheduling is handled in LucidPulseApp based on state

                        Picker("Haptic Pattern", selection: $viewModel.selectedPattern) {
                            ForEach(HapticPattern.allCases) { pattern in
                                Text(pattern.rawValue).tag(pattern)
                            }
                        }
                        // No need to reschedule on pattern change
                    }

                    // Display current settings for clarity
                    Section(header: Text("Current Settings")) {
                         Text("Status: \(viewModel.isReminderActive ? "On" : "Off")")
                         Text("Interval: \(viewModel.selectedInterval.rawValue)")
                         Text("Pattern: \(viewModel.selectedPattern.rawValue)")
                         if viewModel.isReminderActive {
                             Text("Next reminder in: \(viewModel.selectedInterval.timeInterval.formatted()) seconds")
                                 .foregroundColor(.blue)
                         }
                    }

                    // Button for manual testing of haptics
                    Section {
                        Button("Test Haptic") {
                            Task {
                                await viewModel.playSelectedHaptic()
                            }
                        }
                    }
                } else {
                     Text("Reminders are currently disabled.")
                         .foregroundColor(.gray)
                }
            }
            .navigationTitle("LucidPulse")
        }
        // .onAppear removed - scheduling is handled in LucidPulseApp
    }
}

#Preview {
    // Provide a mock ViewModel for the preview
    ContentView()
        .environmentObject(SettingsViewModel())
}
