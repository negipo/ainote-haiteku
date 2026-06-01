import AppKit

/// Google ChromeのタブURLをApple Events経由で取得し、Meetタブの有無を判定する。
/// Chromeが起動していなければ起動させないよう、System Eventsで先に存在確認する。
final class MeetDetector {
    private let pollInterval: TimeInterval
    private var timer: Timer?
    private let onUpdate: (ChromeStatus) -> Void

    init(pollInterval: TimeInterval = 3.0, onUpdate: @escaping (ChromeStatus) -> Void) {
        self.pollInterval = pollInterval
        self.onUpdate = onUpdate
    }

    deinit {
        stop()
    }

    func start() {
        guard timer == nil else { return }
        poll()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func poll() {
        let status = MeetDetector.currentChromeStatus()
        onUpdate(status)
    }

    /// Chromeのタブを走査し現在のChromeStatusを返す。AppleScript失敗時は.unavailable。
    static func currentChromeStatus() -> ChromeStatus {
        guard isChromeRunning() else { return .notRunning }
        guard let urls = fetchTabURLs() else { return .unavailable }
        return AppState.chromeStatus(running: true, urls: urls)
    }

    private static func isChromeRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.google.Chrome"
        }
    }

    /// 全ウィンドウ・全タブのURLを取得する。改行区切りで返るので分割する。
    private static func fetchTabURLs() -> [String]? {
        let source = """
        tell application "Google Chrome"
            set theURLs to ""
            repeat with w in windows
                repeat with t in tabs of w
                    set theURLs to theURLs & (URL of t) & linefeed
                end repeat
            end repeat
            return theURLs
        end tell
        """
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        guard let joined = result.stringValue else { return [] }
        return joined
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }
}
