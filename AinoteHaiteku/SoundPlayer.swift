import AVFoundation
import AppKit

/// バンドルに同梱したm4aをランダムに1つ再生する。
final class SoundPlayer {
    private var player: AVAudioPlayer?
    private let sounds: [URL]

    init(bundle: Bundle = .main) {
        sounds = bundle.urls(forResourcesWithExtension: "m4a", subdirectory: nil) ?? []
    }

    var hasSounds: Bool {
        !sounds.isEmpty
    }

    func playRandom(volume: Float) {
        guard let url = sounds.randomElement() else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.play()
            self.player = player
        } catch {
            NSLog("ainote-haiteku: failed to play %@: %@", url.lastPathComponent, error.localizedDescription)
        }
    }
}
