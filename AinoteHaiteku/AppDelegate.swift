import AppKit

/// 各コンポーネントを束ね、キー押下→状態判定→再生のフローを組み立てる。
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var state: AppState!
    private var statusItemController: StatusItemController!
    private var keyMonitor: KeyMonitor!
    private var meetDetector: MeetDetector!
    private let soundPlayer = SoundPlayer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        state = AppState()

        statusItemController = StatusItemController(state: state)
        statusItemController.onToggleManual = { [weak self] in
            self?.state.toggleManualEnabled()
        }
        statusItemController.onToggleLoginItem = { [weak self] in
            LoginItemController.setEnabled(!LoginItemController.isEnabled)
            self?.statusItemController.refresh()
        }
        statusItemController.onAcquirePermission = { [weak self] in
            self?.acquireAccessibilityPermission()
        }
        statusItemController.onVolumeChange = { [weak self] volume in
            self?.state.setVolume(volume)
        }
        statusItemController.onQuit = {
            NSApplication.shared.terminate(nil)
        }
        statusItemController.keyMonitorActive = { [weak self] in
            self?.keyMonitor.isActive ?? false
        }

        state.onChange = { [weak self] in
            self?.statusItemController.refresh()
        }

        keyMonitor = KeyMonitor { [weak self] in
            self?.handleTrigger()
        }
        keyMonitor.onActivated = { [weak self] in
            self?.statusItemController.refresh()
        }
        meetDetector = MeetDetector { [weak self] status in
            self?.state.updateChromeStatus(status)
        }

        KeyMonitor.ensureAccessibilityPermission(prompt: true)
        LoginItemController.enableIfNeeded()

        keyMonitor.start()
        meetDetector.start()
    }

    /// メニューから任意のタイミングでアクセシビリティ権限を取り直す。
    /// 失効した古いTCCエントリで動かないときに、プロンプト表示と設定パネル誘導を行う。
    private func acquireAccessibilityPermission() {
        KeyMonitor.ensureAccessibilityPermission(prompt: true)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        keyMonitor.start()
    }

    private func handleTrigger() {
        guard state.isEffectivelyActive else { return }
        soundPlayer.playRandom(volume: state.volume)
    }
}
