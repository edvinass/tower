import CoreMotion
import SpriteKit

@MainActor
final class GravityController: ObservableObject {
    @Published var debugPitch: Double = 0
    @Published var debugRoll: Double = 0
    @Published var useDebugInput = false

    private let motionManager = CMMotionManager()
    private var neutralPitch: Double = 0
    private var neutralRoll: Double = 0
    private var filteredGravity = CGVector(dx: 0, dy: -9.8)
    private let maxTiltRadians = 30.0 * .pi / 180.0
    private let smoothing: CGFloat = 0.12
    var tiltSensitivity: Double = 1.0

    func calibrate() {
        neutralPitch = 0
        neutralRoll = 0
        filteredGravity = CGVector(dx: 0, dy: -9.8)
    }

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion, !self.useDebugInput else { return }
            self.update(pitch: motion.attitude.pitch, roll: motion.attitude.roll)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    func updateDebug() {
        update(pitch: debugPitch * .pi / 180, roll: debugRoll * .pi / 180)
    }

    private func update(pitch: Double, roll: Double) {
        let adjPitch = (pitch - neutralPitch) * tiltSensitivity
        let adjRoll = (roll - neutralRoll) * tiltSensitivity
        let clampedPitch = max(-maxTiltRadians, min(maxTiltRadians, adjPitch))
        let clampedRoll = max(-maxTiltRadians, min(maxTiltRadians, adjRoll))
        let magnitude: CGFloat = 9.8
        let target = CGVector(
            dx: CGFloat(sin(clampedRoll)) * magnitude,
            dy: -CGFloat(cos(clampedPitch)) * magnitude
        )
        filteredGravity = CGVector(
            dx: filteredGravity.dx + (target.dx - filteredGravity.dx) * smoothing,
            dy: filteredGravity.dy + (target.dy - filteredGravity.dy) * smoothing
        )
    }

    var gravityVector: CGVector {
        if useDebugInput {
            updateDebug()
        }
        return filteredGravity
    }

    var parallaxOffset: CGPoint {
        CGPoint(x: gravityVector.dx * 0.35, y: 0)
    }
}
