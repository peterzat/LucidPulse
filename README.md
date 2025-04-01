# LucidPulse watchOS App

## Overview

LucidPulse is a watchOS application designed to provide periodic haptic feedback reminders. Users can configure the time interval between reminders and choose from several distinct haptic patterns. The goal is to provide a subtle, configurable "reality check" or mindful moment prompt directly on the Apple Watch.

## Features

*   **Configurable Intervals:** Set reminders for every 15 minutes, 30 minutes, 1 hour, or 2 hours.
*   **Multiple Haptic Patterns:** Choose from different haptic sequences (e.g., Five Long Buzzes, Short/Medium/Long mix, Long/Pause repeats).
*   **On/Off Toggle:** Easily enable or disable the reminders from the main interface.
*   **Background Operation:** Utilizes watchOS background tasks (`BGTaskScheduler`) to ensure haptics are delivered reliably even when the app isn't in the foreground.
*   **SwiftUI Interface:** Modern UI built with SwiftUI for watchOS.
*   **Settings Persistence:** User preferences (interval, pattern, on/off state) are saved using `UserDefaults`.
*   **Telemetry Placeholder:** Includes a basic logging function (`logReminderTriggered`) as a hook for future analytics integration.
*   **Unit Tests:** Basic unit tests for the `SettingsViewModel` are included in the `LucidPulse Watch AppTests` target.

## Setup and Configuration

1.  **Clone the Repository:**
    ```bash
    git clone <repository-url>
    cd LucidPulse
    ```
2.  **Open in Xcode:** Open the `LucidPulse.xcodeproj` file in Xcode.
3.  **Configure Bundle Identifier:**
    *   In the project settings, select each target (`LucidPulse`, `LucidPulse Watch App`).
    *   Go to the **Signing & Capabilities** tab.
    *   Update the **Bundle Identifier** to a unique value using your own reverse domain name (e.g., `com.yourcompany.LucidPulse`). Ensure the Watch App's identifier has the main app's identifier as a prefix.
4.  **Configure Background Task Identifier:**
    *   The background task identifier is currently set to `com.yourappdomain.LucidPulse.reminderTask` in `LucidPulseApp.swift`.
    *   **IMPORTANT:** Replace `com.yourappdomain` with the same reverse domain name used for your Bundle ID.
    *   In the Xcode project settings for the `LucidPulse Watch App` target:
        *   Go to the **Info** tab.
        *   Find the key `BGTaskSchedulerPermittedIdentifiers` (or "Permitted background task scheduler identifiers").
        *   Make sure the value in `Item 0` exactly matches the identifier you set in `LucidPulseApp.swift`.
5.  **Enable Background Modes:**
    *   In the Xcode project settings for the `LucidPulse Watch App` target:
        *   Go to the **Signing & Capabilities** tab.
        *   Click **+ Capability** and add **Background Modes**.
        *   Check the **Background processing** option.
6.  **Build and Run:** Select the `LucidPulse Watch App` scheme and run on a physical Apple Watch or the simulator.

## How it Works

*   **UI (`ContentView.swift`):** Provides toggles and pickers bound to the `SettingsViewModel`.
*   **State Management (`SettingsViewModel.swift`):** An `ObservableObject` that holds the current settings (`isReminderActive`, `selectedInterval`, `selectedPattern`), saves them to `UserDefaults`, and contains the logic to play haptic patterns (`playSelectedHaptic`).
*   **App Lifecycle & Scheduling (`LucidPulseApp.swift`):** The main app struct initializes the `SettingsViewModel` and passes it to the `ContentView`. It uses `@Environment(\.scenePhase)` and the `@Published` properties of the ViewModel to detect when to schedule or cancel background tasks via `BGTaskScheduler.shared.submit()` and `BGTaskScheduler.shared.cancel()`. It also registers a handler (`.backgroundTask(.appRefresh(...))`) that the system calls to execute the background task.
*   **Background Task Handling:** When the background task runs, the handler in `LucidPulseApp.swift` calls `scheduleAppRefresh()` again to queue the *next* reminder and then calls `settingsViewModel.playSelectedHaptic()` to trigger the vibration.
*   **Haptics:** The `playSelectedHaptic` function in `SettingsViewModel` uses `WKInterfaceDevice.current().play()` combined with `Task.sleep` to create custom haptic sequences.

## Building for App Store

1.  Ensure all Bundle Identifiers are unique and correctly configured.
2.  Set up App Store Connect record, provisioning profiles, and certificates.
3.  Use Xcode's **Product > Archive** menu.
4.  Upload the archive using Xcode's Organizer.

## Testing

*   **Unit Tests:** Run the tests in the `LucidPulse Watch AppTests` target using **Product > Test** in Xcode.
*   **Manual Testing:** Run the app on a device/simulator. Test toggling reminders on/off, changing intervals/patterns, and background functionality (set a short interval like 15 min, send the app to the background, and wait).

# WatchOS App Icon Generator

This Python script generates all required icon sizes for a watchOS app from a single 1024x1024 source image.

## Requirements

- Python 3.6 or higher
- Pillow library

## Installation

1. Install the required dependencies:
```bash
pip install -r requirements.txt
```

## Usage

Run the script with your 1024x1024 source image:

```bash
python generate_watch_icons.py path/to/your/icon.png
```

By default, the generated icons will be saved in a `watch_icons` directory. You can specify a different output directory using the `--output-dir` option:

```bash
python generate_watch_icons.py path/to/your/icon.png --output-dir my_icons
```

## Generated Icon Sizes

The script generates the following icon sizes:

### App Store
- 1024x1024

### Quick Look
- 108x108 (49mm)
- 97x97 (45mm)
- 94x94 (44mm)
- 86x86 (41mm)
- 80x80 (38mm)

### App Launcher
- 100x100 (49mm)
- 92x92 (45mm)
- 88x88 (44mm)

### Notification Center
- 66x66 (45mm)
- 58x58 (41mm)

### Companion Settings
- 87x87 (@3x)

### Additional Sizes
- 48x48
- 55x55
- 66x66
- 58x58
- 87x87
- 80x80
- 88x88
- 92x92
- 100x100
- 102x102
- 108x108
- 172x172
- 196x196
- 216x216
- 234x234
- 258x258

## Output

The generated icons will be named with the pattern: `original_name-widthxheight.png`

Example: If your source image is named `app_icon.png`, the generated files will be:
- `app_icon-1024x1024.png`
- `app_icon-108x108.png`
- `app_icon-97x97.png`
etc. 