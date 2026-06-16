import AVFoundation
import AudioToolbox

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var players: [String: AVAudioPlayer] = [:]
    private var windPlayer: AVAudioPlayer?
    private var isConfigured = false

    private init() {}

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func playImpact(for material: Material) {
        configure()
        let soundID: SystemSoundID
        switch material {
        case .wood: soundID = 1104
        case .ice: soundID = 1103
        case .rubber: soundID = 1105
        case .metal: soundID = 1057
        }
        AudioServicesPlaySystemSound(soundID)
    }

    func playUIClick() {
        AudioServicesPlaySystemSound(1104)
    }

    func playWin() {
        AudioServicesPlaySystemSound(1025)
    }

    func playFail() {
        AudioServicesPlaySystemSound(1073)
    }

    func playGust() {
        AudioServicesPlaySystemSound(1106)
    }

    func updateWindVolume(strength: Double) {
        // Placeholder for wind loop volume when audio assets are added
        _ = strength
    }
}
