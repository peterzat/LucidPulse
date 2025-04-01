import XCTest
@testable import LucidPulse_Watch_App // Import the main app module
import Combine

final class SettingsViewModelTests: XCTestCase {

    var viewModel: SettingsViewModel!
    var cancellables: Set<AnyCancellable>!
    let testDefaultsSuiteName = "TestDefaults"

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Use a specific UserDefaults suite for testing to avoid polluting production defaults
        UserDefaults().removePersistentDomain(forName: testDefaultsSuiteName)
        let testDefaults = UserDefaults(suiteName: testDefaultsSuiteName)!

        // Inject the test UserDefaults into the ViewModel
        // Note: This requires modifying SettingsViewModel to accept UserDefaults in its init,
        // or using a different dependency injection approach.
        // For now, we'll test the default initializer which uses UserDefaults.standard,
        // but be aware this tests against the actual standard defaults, which isn't ideal.
        // A better approach is dependency injection.
        viewModel = SettingsViewModel() // Ideally: SettingsViewModel(userDefaults: testDefaults)
        cancellables = []
    }

    override func tearDownWithError() throws {
        // Clean up test defaults
        UserDefaults().removePersistentDomain(forName: testDefaultsSuiteName)
        viewModel = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // Test initial default values
    func testInitialDefaultValues() {
        XCTAssertFalse(viewModel.isReminderActive, "Default active state should be false")
        XCTAssertEqual(viewModel.selectedInterval, .oneHour, "Default interval should be one hour")
        XCTAssertEqual(viewModel.selectedPattern, .fiveLong, "Default pattern should be five long")
    }

    // Test saving and loading the active state
    func testIsReminderActivePersistence() {
        let expectation = XCTestExpectation(description: "isReminderActive changes are saved and loaded")

        // 1. Change the value
        viewModel.isReminderActive = true
        XCTAssertTrue(viewModel.isReminderActive)

        // Allow UserDefaults to save (usually synchronous, but good practice for async tests)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 2. Create a new ViewModel instance to force loading from UserDefaults
            let newViewModel = SettingsViewModel() // Again, ideally with injected testDefaults
            XCTAssertTrue(newViewModel.isReminderActive, "New ViewModel should load the saved active state")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // Test saving and loading the interval
    func testSelectedIntervalPersistence() {
        let expectation = XCTestExpectation(description: "selectedInterval changes are saved and loaded")
        let testInterval = ReminderInterval.thirtyMinutes

        viewModel.selectedInterval = testInterval
        XCTAssertEqual(viewModel.selectedInterval, testInterval)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newViewModel = SettingsViewModel()
            XCTAssertEqual(newViewModel.selectedInterval, testInterval, "New ViewModel should load the saved interval")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // Test saving and loading the pattern
    func testSelectedPatternPersistence() {
        let expectation = XCTestExpectation(description: "selectedPattern changes are saved and loaded")
        let testPattern = HapticPattern.shortMediumLong

        viewModel.selectedPattern = testPattern
        XCTAssertEqual(viewModel.selectedPattern, testPattern)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let newViewModel = SettingsViewModel()
            XCTAssertEqual(newViewModel.selectedPattern, testPattern, "New ViewModel should load the saved pattern")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // Test that playSelectedHaptic is callable (basic check)
    // Note: Testing actual haptic output requires UI tests or mocking WKInterfaceDevice
    func testPlaySelectedHapticIsCallable() {
        // Simply call the function to ensure it doesn't crash.
        // More advanced tests could involve mocking WKInterfaceDevice.
         viewModel.playSelectedHaptic() // Needs @MainActor context
        // No assertion needed here, just checking for crashes/errors during the call.
        // To properly test async behavior, we might need expectations.
    }

     // Test telemetry log function is callable
    func testLogReminderTriggeredIsCallable() {
        viewModel.logReminderTriggered()
        // No assertion, just checking it runs without crashing.
    }
} 