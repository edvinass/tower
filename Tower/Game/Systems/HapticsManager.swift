import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notification.prepare()
    }

    func blockPlaced() {
        light.impactOccurred()
    }

    func gustWarning() {
        medium.impactOccurred()
    }

    func collapse() {
        heavy.impactOccurred(intensity: 1.0)
    }

    func levelComplete() {
        notification.notificationOccurred(.success)
    }

    func levelFailed() {
        notification.notificationOccurred(.error)
    }
}
