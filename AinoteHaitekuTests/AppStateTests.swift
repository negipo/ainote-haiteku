import XCTest
@testable import ainote_haiteku

final class AppStateTests: XCTestCase {
    private func makeState() -> AppState {
        let defaults = UserDefaults(suiteName: "ainote-haiteku.tests.\(UUID().uuidString)")!
        return AppState(defaults: defaults)
    }

    func testDefaultIsManuallyEnabled() {
        let state = makeState()
        XCTAssertTrue(state.manualEnabled)
    }

    func testActiveWhenEnabledAndNoMeet() {
        let state = makeState()
        state.updateChromeStatus(.noMeet)
        XCTAssertTrue(state.isEffectivelyActive)
    }

    func testInactiveWhenManuallyDisabled() {
        let state = makeState()
        state.updateChromeStatus(.noMeet)
        state.setManualEnabled(false)
        XCTAssertFalse(state.isEffectivelyActive)
    }

    func testInactiveWhenMeetDetectedEvenIfEnabled() {
        let state = makeState()
        state.updateChromeStatus(.meetDetected(tabCount: 1))
        XCTAssertFalse(state.isEffectivelyActive)
    }

    func testNotRunningKeepsActive() {
        let state = makeState()
        state.updateChromeStatus(.notRunning)
        XCTAssertTrue(state.isEffectivelyActive)
    }

    func testUnavailableKeepsActive() {
        let state = makeState()
        state.updateChromeStatus(.unavailable)
        XCTAssertTrue(state.isEffectivelyActive)
    }

    func testChromeStatusFromURLsDetectsMeet() {
        let urls = ["https://github.com/", "https://meet.google.com/abc-defg-hij"]
        XCTAssertEqual(AppState.chromeStatus(running: true, urls: urls), .meetDetected(tabCount: 1))
    }

    func testChromeStatusCountsMultipleMeetTabs() {
        let urls = [
            "https://meet.google.com/abc-defg-hij",
            "https://meet.google.com/klm-nopq-rst",
            "https://example.com/"
        ]
        XCTAssertEqual(AppState.chromeStatus(running: true, urls: urls), .meetDetected(tabCount: 2))
    }

    func testChromeStatusNoMeet() {
        let urls = ["https://github.com/", "https://example.com/"]
        XCTAssertEqual(AppState.chromeStatus(running: true, urls: urls), .noMeet)
    }

    func testChromeStatusNotRunning() {
        XCTAssertEqual(AppState.chromeStatus(running: false, urls: []), .notRunning)
    }

    func testDefaultVolumeIsMax() {
        let state = makeState()
        XCTAssertEqual(state.volume, 1.0)
    }

    func testSetVolumeClampsAboveOne() {
        let state = makeState()
        state.setVolume(1.5)
        XCTAssertEqual(state.volume, 1.0)
    }

    func testSetVolumeClampsBelowZero() {
        let state = makeState()
        state.setVolume(-0.5)
        XCTAssertEqual(state.volume, 0.0)
    }

    func testVolumePersistsAcrossInstances() {
        let suite = "ainote-haiteku.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let first = AppState(defaults: defaults)
        first.setVolume(0.3)
        let second = AppState(defaults: defaults)
        XCTAssertEqual(second.volume, 0.3, accuracy: 0.0001)
    }
}
