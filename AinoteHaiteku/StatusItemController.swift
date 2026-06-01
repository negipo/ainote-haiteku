import AppKit

/// メニューバーのNSStatusItemとメニューを管理する。状態に応じてアイコンとメニュー文言を更新する。
final class StatusItemController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let state: AppState

    var onToggleManual: (() -> Void)?
    var onToggleLoginItem: (() -> Void)?
    var onAcquirePermission: (() -> Void)?
    var onVolumeChange: ((Float) -> Void)?
    var onQuit: (() -> Void)?

    /// キー監視が現在有効か(=アクセシビリティ権限が実効的に付与されているか)を返す。
    var keyMonitorActive: () -> Bool = { false }

    init(state: AppState) {
        self.state = state
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        refresh()
    }

    /// アイコンとメニュー内容を現在の状態へ更新する。
    func refresh() {
        statusItem.button?.image = StatusItemIcon.image(active: state.isEffectivelyActive)
        rebuildMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        let statusTitle = state.isEffectivelyActive ? "Status: Active" : "Status: Inactive"
        menu.addItem(disabledItem(statusTitle))

        for reason in inactiveReasons() {
            menu.addItem(disabledItem("  – \(reason)"))
        }

        menu.addItem(disabledItem("Chrome: \(chromeDescription())"))
        menu.addItem(disabledItem("Key monitor: \(keyMonitorActive() ? "Active" : "Needs permission")"))

        menu.addItem(.separator())

        let enabledItem = NSMenuItem(
            title: "Enabled",
            action: #selector(toggleManual),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = state.manualEnabled ? .on : .off
        menu.addItem(enabledItem)

        menu.addItem(buildVolumeMenuItem())

        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsItem.submenu = buildSettingsMenu()
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    /// 音量スライダーを載せたメニュー項目。スピーカーアイコン + NSSliderの横並び。
    private func buildVolumeMenuItem() -> NSMenuItem {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 28))

        let icon = NSImageView(frame: NSRect(x: 14, y: 6, width: 16, height: 16))
        icon.image = NSImage(systemSymbolName: "speaker.wave.2.fill", accessibilityDescription: "Volume")
        icon.contentTintColor = .secondaryLabelColor
        container.addSubview(icon)

        let slider = NSSlider(frame: NSRect(x: 38, y: 4, width: 150, height: 20))
        slider.minValue = 0.0
        slider.maxValue = 1.0
        slider.floatValue = state.volume
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(volumeChanged(_:))
        container.addSubview(slider)

        let item = NSMenuItem()
        item.view = container
        return item
    }

    private func buildSettingsMenu() -> NSMenu {
        let submenu = NSMenu()

        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLoginItem),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItemController.isEnabled ? .on : .off
        submenu.addItem(loginItem)

        let permissionItem = NSMenuItem(
            title: "Acquire Accessibility Permission",
            action: #selector(acquirePermission),
            keyEquivalent: ""
        )
        permissionItem.target = self
        submenu.addItem(permissionItem)

        return submenu
    }

    private func inactiveReasons() -> [String] {
        var reasons: [String] = []
        if !state.manualEnabled {
            reasons.append("Manually disabled")
        }
        if state.chromeStatus.suppressesSound {
            reasons.append("Google Meet in progress")
        }
        return reasons
    }

    private func chromeDescription() -> String {
        switch state.chromeStatus {
        case .notRunning:
            return "Not running"
        case .noMeet:
            return "No Meet"
        case .meetDetected(let tabCount):
            return "Meet detected (\(tabCount) tab\(tabCount == 1 ? "" : "s"))"
        case .unavailable:
            return "Detection unavailable (grant Automation)"
        }
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func toggleManual() {
        onToggleManual?()
    }

    @objc private func toggleLoginItem() {
        onToggleLoginItem?()
    }

    @objc private func acquirePermission() {
        onAcquirePermission?()
    }

    @objc private func volumeChanged(_ sender: NSSlider) {
        onVolumeChange?(sender.floatValue)
    }

    @objc private func quit() {
        onQuit?()
    }
}
