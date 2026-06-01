import Foundation

/// Chromeのタブ検査結果。Meet判定はこの値域で表現する。
enum ChromeStatus: Equatable {
    case notRunning
    case noMeet
    case meetDetected(tabCount: Int)
    case unavailable

    var suppressesSound: Bool {
        if case .meetDetected = self { return true }
        return false
    }
}

/// 手動トグル(マスタースイッチ)とChrome状態(自動ゲート)を直交ANDで合成する状態モデル。
final class AppState {
    private enum Keys {
        static let manualEnabled = "manualEnabled"
        static let volume = "volume"
    }

    private let defaults: UserDefaults

    /// 状態変化のたびに呼ばれる。UI更新のフック。
    var onChange: (() -> Void)?

    private(set) var manualEnabled: Bool {
        didSet {
            guard manualEnabled != oldValue else { return }
            defaults.set(manualEnabled, forKey: Keys.manualEnabled)
            onChange?()
        }
    }

    private(set) var chromeStatus: ChromeStatus = .notRunning {
        didSet {
            guard chromeStatus != oldValue else { return }
            onChange?()
        }
    }

    /// 再生音量(0.0...1.0)。UserDefaultsに永続化。
    /// 音量はアイコン・メニュー文言に影響しないため、変更時にonChangeは呼ばない
    /// (スライダーのドラッグ中にメニューが再構築されるのを避ける)。
    private(set) var volume: Float {
        didSet {
            let clamped = AppState.clampVolume(volume)
            if clamped != volume {
                volume = clamped
                return
            }
            guard volume != oldValue else { return }
            defaults.set(volume, forKey: Keys.volume)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.manualEnabled) == nil {
            defaults.set(true, forKey: Keys.manualEnabled)
        }
        self.manualEnabled = defaults.bool(forKey: Keys.manualEnabled)
        if defaults.object(forKey: Keys.volume) == nil {
            defaults.set(1.0, forKey: Keys.volume)
        }
        self.volume = AppState.clampVolume(defaults.float(forKey: Keys.volume))
    }

    /// 実際に音を鳴らすか。手動が有効 かつ Meetを開いていない とき真。
    var isEffectivelyActive: Bool {
        manualEnabled && !chromeStatus.suppressesSound
    }

    func setManualEnabled(_ enabled: Bool) {
        manualEnabled = enabled
    }

    func toggleManualEnabled() {
        manualEnabled.toggle()
    }

    func updateChromeStatus(_ status: ChromeStatus) {
        chromeStatus = status
    }

    func setVolume(_ newValue: Float) {
        volume = newValue
    }

    static func clampVolume(_ value: Float) -> Float {
        min(max(value, 0.0), 1.0)
    }

    /// 与えられたURL集合からMeetタブ数を数え、ChromeStatusへ変換する純粋関数。
    static func chromeStatus(running: Bool, urls: [String]) -> ChromeStatus {
        guard running else { return .notRunning }
        let meetCount = urls.filter { isMeetURL($0) }.count
        return meetCount > 0 ? .meetDetected(tabCount: meetCount) : .noMeet
    }

    /// URLがGoogle MeetのミーティングURLかどうか。
    static func isMeetURL(_ url: String) -> Bool {
        url.range(of: "://meet.google.com/", options: .caseInsensitive) != nil
    }
}
