import AppKit

/// グローバルなキー押下を監視し、ainoteのトリガー(Enter / テンキーEnter / Ctrl+M)で
/// コールバックを呼ぶ。読み取り専用モニタなのでキー入力自体は消費しない。
final class KeyMonitor {
    private enum KeyCode {
        static let returnKey: UInt16 = 36
        static let keypadEnter: UInt16 = 76
        static let mKey: UInt16 = 46
    }

    private var monitor: Any?
    private var trustTimer: Timer?
    private let onTrigger: () -> Void

    /// 監視が実際に有効になったとき(=アクセシビリティ権限が付与され登録できたとき)に呼ばれる。
    var onActivated: (() -> Void)?

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
    }

    deinit {
        stop()
    }

    /// アクセシビリティ権限が付与済みかどうか。未付与時はpromptで許可ダイアログを出す。
    @discardableResult
    static func ensureAccessibilityPermission(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    var isActive: Bool {
        monitor != nil
    }

    /// 権限があれば即座に監視を登録する。なければ権限が付与されるまで待ってから登録する。
    /// グローバル監視は登録時点でイベントタップを張るため、権限付与後に登録し直す必要がある。
    func start() {
        guard monitor == nil else { return }
        if AXIsProcessTrusted() {
            install()
        } else {
            startTrustPolling()
        }
    }

    func stop() {
        trustTimer?.invalidate()
        trustTimer = nil
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func install() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }
        onActivated?()
    }

    private func startTrustPolling() {
        guard trustTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if AXIsProcessTrusted() {
                self.trustTimer?.invalidate()
                self.trustTimer = nil
                self.install()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        trustTimer = timer
    }

    private func handle(_ event: NSEvent) {
        if KeyMonitor.isTrigger(keyCode: event.keyCode, hasControl: event.modifierFlags.contains(.control)) {
            onTrigger()
        }
    }

    /// ainote相当のトリガー判定。Enter/テンキーEnter、またはCtrl+M。
    static func isTrigger(keyCode: UInt16, hasControl: Bool) -> Bool {
        switch keyCode {
        case KeyCode.returnKey, KeyCode.keypadEnter:
            return true
        case KeyCode.mKey:
            return hasControl
        default:
            return false
        }
    }
}
