import AppKit

/// メニューバーアイコンを生成する。ベース記号に対し、無効時は右下へ小さな×バッジを重ねる。
enum StatusItemIcon {
    private static let size = NSSize(width: 18, height: 18)

    static func image(active: Bool) -> NSImage {
        let base = baseSymbol()
        guard !active else {
            base.isTemplate = true
            return base
        }
        return withCrossBadge(base)
    }

    private static func baseSymbol() -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "ainote-haiteku")?
            .withSymbolConfiguration(config)
        return image ?? NSImage(size: size)
    }

    private static func withCrossBadge(_ base: NSImage) -> NSImage {
        let canvas = NSImage(size: size)
        canvas.lockFocus()
        defer { canvas.unlockFocus() }

        let baseRect = NSRect(origin: .zero, size: size)
        base.isTemplate = true
        base.draw(in: baseRect, from: .zero, operation: .sourceOver, fraction: 0.9)

        let badgeConfig = NSImage.SymbolConfiguration(pointSize: 9, weight: .bold)
        if let badge = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "disabled")?
            .withSymbolConfiguration(badgeConfig) {
            let badgeSize = badge.size
            let badgeRect = NSRect(
                x: size.width - badgeSize.width,
                y: 0,
                width: badgeSize.width,
                height: badgeSize.height
            )
            badge.draw(in: badgeRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        }

        canvas.isTemplate = true
        return canvas
    }
}
