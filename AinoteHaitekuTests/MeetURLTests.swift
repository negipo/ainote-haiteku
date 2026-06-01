import XCTest
@testable import ainote_haiteku

final class MeetURLTests: XCTestCase {
    func testMatchesMeetMeetingURL() {
        XCTAssertTrue(AppState.isMeetURL("https://meet.google.com/abc-defg-hij"))
    }

    func testMatchesWithQueryString() {
        XCTAssertTrue(AppState.isMeetURL("https://meet.google.com/abc-defg-hij?authuser=0"))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(AppState.isMeetURL("HTTPS://MEET.GOOGLE.COM/abc"))
    }

    func testDoesNotMatchGoogleSearch() {
        XCTAssertFalse(AppState.isMeetURL("https://www.google.com/search?q=meet.google.com"))
    }

    func testDoesNotMatchSubstringInPath() {
        XCTAssertFalse(AppState.isMeetURL("https://example.com/meet.google.com/fake"))
    }

    func testDoesNotMatchEmpty() {
        XCTAssertFalse(AppState.isMeetURL(""))
    }
}

final class KeyTriggerTests: XCTestCase {
    func testReturnKeyTriggers() {
        XCTAssertTrue(KeyMonitor.isTrigger(keyCode: 36, hasControl: false))
    }

    func testKeypadEnterTriggers() {
        XCTAssertTrue(KeyMonitor.isTrigger(keyCode: 76, hasControl: false))
    }

    func testControlMTriggers() {
        XCTAssertTrue(KeyMonitor.isTrigger(keyCode: 46, hasControl: true))
    }

    func testPlainMDoesNotTrigger() {
        XCTAssertFalse(KeyMonitor.isTrigger(keyCode: 46, hasControl: false))
    }

    func testOtherKeyDoesNotTrigger() {
        XCTAssertFalse(KeyMonitor.isTrigger(keyCode: 0, hasControl: false))
    }
}
