import Foundation
import SpriteKit

final class WindSystem {
    let config: WindConfig
    private(set) var currentStrength: Double = 0
    private(set) var direction: CGFloat = 1
    private(set) var gustWarning = false

    private var elapsed: TimeInterval = 0
    private var nextGustTime: TimeInterval = 5
    private var gustPhase: GustPhase = .idle
    private var gustStart: TimeInterval = 0
    private var gustSpike: Double = 0
    private var resolvedDirection: CGFloat = 1

    private enum GustPhase {
        case idle
        case telegraph
        case active
    }

    init(config: WindConfig) {
        self.config = config
        resolvedDirection = resolveDirection()
        direction = resolvedDirection
        scheduleNextGust(after: 3)
    }

    func update(deltaTime: TimeInterval) {
        guard config.baseStrength > 0 else {
            currentStrength = 0
            gustWarning = false
            return
        }

        elapsed += deltaTime
        updateGusts()

        let oscillation = sin(elapsed * 1.4) * 0.15
        currentStrength = max(0, config.baseStrength + oscillation + gustSpike)
    }

    private func updateGusts() {
        guard config.gustFrequency > 0 else {
            gustWarning = false
            gustSpike = 0
            return
        }

        switch gustPhase {
        case .idle:
            gustWarning = false
            gustSpike = 0
            if elapsed >= nextGustTime {
                gustPhase = .telegraph
                gustStart = elapsed
                gustWarning = true
            }
        case .telegraph:
            gustWarning = true
            if elapsed - gustStart >= 0.5 {
                gustPhase = .active
                gustStart = elapsed
                gustSpike = config.baseStrength * 0.8
                resolvedDirection = resolveDirection()
                direction = resolvedDirection
            }
        case .active:
            gustWarning = true
            if elapsed - gustStart >= 1.5 {
                gustPhase = .idle
                gustWarning = false
                gustSpike = 0
                scheduleNextGust(after: randomGustInterval())
            }
        }
    }

    private func scheduleNextGust(after interval: TimeInterval) {
        nextGustTime = elapsed + interval
    }

    private func randomGustInterval() -> TimeInterval {
        let base = 4.0 / max(config.gustFrequency, 0.05)
        return base + Double.random(in: -1...2)
    }

    private func resolveDirection() -> CGFloat {
        switch config.direction {
        case .left: return -1
        case .right: return 1
        case .random: return Bool.random() ? 1 : -1
        }
    }

    func force(for block: BlockNode) -> CGVector {
        guard currentStrength > 0, block.isPlaced, block.physicsBody?.isDynamic == true else {
            return .zero
        }
        let drag = block.spec.material.dragCoefficient
        let areaFactor = block.exposedWidth / 60.0
        let magnitude = CGFloat(currentStrength) * drag * areaFactor * 120
        return CGVector(dx: magnitude * direction, dy: 0)
    }
}
