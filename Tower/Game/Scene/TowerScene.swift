import SpriteKit
import UIKit

@MainActor
protocol TowerSceneProtocol: AnyObject {
    func rotatePendingBlock()
    func placeBlock(at scenePoint: CGPoint) -> Bool
    func updateGhost(at scenePoint: CGPoint?)
    func isReadyForPlacement() -> Bool
    func pause()
    func resume()
    func retry()
}

@MainActor
final class TowerScene: SKScene, TowerSceneProtocol {
    weak var gameDelegate: TowerSceneDelegate?

    private var level: LevelConfig!
    private var platform: PlatformNode!
    private var cameraNode: SKCameraNode!
    private var wobbleContainer: SKNode!
    private var placedBlocks: [BlockNode] = []
    private var ghostBlock: BlockNode?
    private var lastGhostPosition: CGPoint?
    private var windSystem: WindSystem!
    private var heightTracker = HeightTracker(
        platformTopY: 0,
        targetHeightAbovePlatform: 10,
        holdDuration: 2,
        failLineY: -100
    )
    private var gravityController = GravityController()
    private var windEmitter: SKEmitterNode!
    private var confettiEmitter: SKEmitterNode?

    private var queueIndex = 0
    private var rotationSteps = 0
    private var selectedQueueOffset = 0
    private var blocksPlaced = 0
    private var anyBlockCrossedFailLine = false
    private var placementCooldownUntil: TimeInterval = 0
    private var gamePaused = false
    private var gameEnded = false
    private var lastTime: TimeInterval = 0
    private var lastGustWarning = false
    private var nearFail = false
    private var lastHUDPublishTime: TimeInterval = 0
    private let hudPublishInterval: TimeInterval = 0.12
    private var earnedStars = 0
    private var outOfBlocksSince: TimeInterval?

    private let placementCooldown: TimeInterval = 0.05

    func configure(level: LevelConfig, gravityController: GravityController) {
        self.level = level
        self.gravityController = gravityController
        self.gravityController.tiltSensitivity = level.tiltSensitivity
        self.windSystem = WindSystem(config: level.wind)
        self.heightTracker = HeightTracker(
            platformTopY: 0,
            targetHeightAbovePlatform: CGFloat(level.targetHeight),
            holdDuration: level.holdDuration,
            failLineY: -200
        )
        queueIndex = 0
        rotationSteps = 0
        selectedQueueOffset = 0
        blocksPlaced = 0
        anyBlockCrossedFailLine = false
        gameEnded = false
        earnedStars = 0
        outOfBlocksSince = nil
        gamePaused = false
        placedBlocks.removeAll()
        ghostBlock?.removeFromParent()
        ghostBlock = nil
        lastGhostPosition = nil
    }

    override func didMove(to view: SKView) {
        guard level != nil else { return }
        setupScene()
    }

    private func setupScene() {
        backgroundColor = SKColor(red: 0.53, green: 0.75, blue: 0.92, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        removeAllChildren()
        placedBlocks.removeAll()

        let bg = SKSpriteNode(color: SKColor(red: 0.45, green: 0.68, blue: 0.88, alpha: 1), size: CGSize(width: 3000, height: 3000))
        bg.position = CGPoint(x: 0, y: 500)
        bg.zPosition = -100
        addChild(bg)

        wobbleContainer = SKNode()
        addChild(wobbleContainer)

        platform = PlatformNode(width: CGFloat(level.platformWidth * 20))
        platform.position = CGPoint(x: 0, y: -size.height / 2 + 120)
        wobbleContainer.addChild(platform)

        heightTracker = HeightTracker(
            platformTopY: platform.topY,
            targetHeightAbovePlatform: CGFloat(level.targetHeight),
            holdDuration: level.holdDuration,
            failLineY: platform.failLineY
        )

        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = CGPoint(x: 0, y: platform.topY + 80)

        setupWindEmitter()
        drawTargetLine()
        gravityController.calibrate()
        gravityController.start()
        publishState()
    }

    private func drawTargetLine() {
        let lineY = platform.topY + CGFloat(level.targetHeight)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -400, y: lineY))
        path.addLine(to: CGPoint(x: 400, y: lineY))
        let line = SKShapeNode(path: path)
        line.strokeColor = SKColor(white: 1, alpha: 0.45)
        line.lineWidth = 2
        line.zPosition = -10
        wobbleContainer.addChild(line)

        let label = SKLabelNode(text: "TARGET")
        label.fontSize = 12
        label.fontColor = SKColor(white: 1, alpha: 0.6)
        label.position = CGPoint(x: -180, y: lineY + 6)
        label.zPosition = -10
        wobbleContainer.addChild(label)
    }

    private func setupWindEmitter() {
        windEmitter = SKEmitterNode()
        windEmitter.particleTexture = Self.makeParticleTexture()
        windEmitter.particleBirthRate = 0
        windEmitter.particleLifetime = 2
        windEmitter.particleSpeed = 40
        windEmitter.particleSpeedRange = 20
        windEmitter.particleAlpha = 0.35
        windEmitter.particleAlphaRange = 0.2
        windEmitter.particleScale = 0.08
        windEmitter.particleColor = SKColor(white: 1, alpha: 0.8)
        windEmitter.particleColorBlendFactor = 1
        windEmitter.emissionAngleRange = .pi / 8
        windEmitter.position = CGPoint(x: 0, y: 200)
        windEmitter.zPosition = 50
        addChild(windEmitter)
    }

    override func update(_ currentTime: TimeInterval) {
        guard !gamePaused, !gameEnded, level != nil else { return }

        let delta = lastTime == 0 ? 0 : currentTime - lastTime
        lastTime = currentTime

        physicsWorld.gravity = gravityController.gravityVector
        windSystem.update(deltaTime: delta)
        applyWind()

        if windSystem.gustWarning && !lastGustWarning {
            gameDelegate?.sceneDidWarnGust()
            HapticsManager.shared.gustWarning()
        }
        lastGustWarning = windSystem.gustWarning

        updateWindParticles()
        updateCamera()
        updateWobble()
        checkFailures()
        evaluateHeight(at: currentTime)
        checkOutOfBlocks(at: currentTime)
        publishHUDIfNeeded(at: currentTime)
    }

    private var isOutOfBlocks: Bool {
        blocksPlaced >= level.maxBlocks || queueIndex >= level.blockSpecs.count
    }

    private func blocksAreSettled() -> Bool {
        !placedBlocks.isEmpty && placedBlocks.allSatisfy { $0.physicsBody?.isResting == true }
    }

    private func checkOutOfBlocks(at time: TimeInterval) {
        guard isOutOfBlocks else {
            outOfBlocksSince = nil
            return
        }

        if heightTracker.currentHeight >= CGFloat(level.targetHeight) {
            outOfBlocksSince = nil
            return
        }

        if outOfBlocksSince == nil {
            outOfBlocksSince = time
        }
        guard let started = outOfBlocksSince else { return }

        let waited = time - started
        let settled = blocksAreSettled()
        guard waited >= 0.8, settled || waited >= 4 else { return }

        triggerOutOfBlocks()
    }

    private func publishHUDIfNeeded(at time: TimeInterval) {
        guard !gameEnded else { return }
        guard time - lastHUDPublishTime >= hudPublishInterval else { return }
        lastHUDPublishTime = time
        publishState()
    }

    private func applyWind() {
        for block in placedBlocks {
            let force = windSystem.force(for: block)
            if force != .zero {
                block.physicsBody?.applyForce(force)
                if block.physicsBody?.isResting == true {
                    block.physicsBody?.isResting = false
                }
            }
        }
    }

    private func updateWindParticles() {
        let strength = windSystem.currentStrength
        windEmitter.particleBirthRate = CGFloat(strength) * 30
        windEmitter.particleSpeed = 30 + CGFloat(strength) * 60
        let dir = windSystem.direction
        windEmitter.emissionAngle = dir > 0 ? 0 : .pi
        windEmitter.position.y = cameraNode.position.y
    }

    private func updateCamera() {
        let targetY: CGFloat
        if placedBlocks.isEmpty {
            targetY = platform.topY + 120
        } else {
            let maxY = placedBlocks.map { $0.calculateAccumulatedFrame().maxY }.max() ?? platform.topY
            targetY = max(platform.topY + 120, maxY + 80)
        }
        let parallax = gravityController.parallaxOffset
        cameraNode.position = CGPoint(
            x: parallax.x,
            y: cameraNode.position.y + (targetY - cameraNode.position.y) * 0.06
        )
    }

    private func updateWobble() {
        guard !placedBlocks.isEmpty else { return }
        let avgX = placedBlocks.map(\.position.x).reduce(0, +) / CGFloat(placedBlocks.count)
        let offsetX = avgX * 0.02 + gravityController.gravityVector.dx * 0.08
        wobbleContainer.position.x += (offsetX - wobbleContainer.position.x) * 0.08
    }

    private func checkFailures() {
        var anyNear = false
        for block in placedBlocks {
            if heightTracker.blockFailed(block, platform: platform) {
                if block.calculateAccumulatedFrame().maxY < platform.failLineY {
                    anyBlockCrossedFailLine = true
                }
                triggerFail()
                return
            }
            let frame = block.calculateAccumulatedFrame()
            if frame.maxY < platform.topY + 20 && frame.minY < platform.failLineY + 60 {
                anyNear = true
            }
        }
        if anyNear != nearFail {
            nearFail = anyNear
            gameDelegate?.sceneDidNearFail(anyNear)
        }
    }

    private func evaluateHeight(at time: TimeInterval) {
        let result = heightTracker.update(blocks: placedBlocks, time: time)
        switch result {
        case .won:
            triggerWin()
        case .failedDroppedBelow:
            triggerFail()
        default:
            break
        }
    }

    func rotatePendingBlock() {
        guard !gameEnded else { return }
        rotationSteps = (rotationSteps + 1) % 4
        updateGhost(at: ghostBlock?.position ?? lastGhostPosition)
        publishState()
    }

    func updateGhost(at scenePoint: CGPoint?) {
        guard !gameEnded, let spec = currentSpec() else {
            ghostBlock?.removeFromParent()
            ghostBlock = nil
            return
        }

        if ghostBlock?.spec != spec || ghostBlock?.rotationSteps != rotationSteps {
            ghostBlock?.removeFromParent()
            ghostBlock = BlockNode.make(spec: spec, rotationSteps: rotationSteps, isGhost: true)
            if let ghostBlock { wobbleContainer.addChild(ghostBlock) }
        }

        if let scenePoint {
            lastGhostPosition = scenePoint
            ghostBlock?.position = scenePoint
            let valid = isValidPlacement(for: ghostBlock)
            ghostBlock?.fillColor = valid ? spec.material.fillColor.withAlphaComponent(0.55) : SKColor.red.withAlphaComponent(0.45)
        }
    }

    func placeBlock(at scenePoint: CGPoint) -> Bool {
        guard !gameEnded, !gamePaused else { return false }
        guard CACurrentMediaTime() >= placementCooldownUntil else { return false }
        guard let spec = currentSpec() else { return false }

        let block = BlockNode.make(spec: spec, rotationSteps: rotationSteps)
        block.position = scenePoint
        wobbleContainer.addChild(block)

        guard isValidPlacement(for: block) else {
            block.playInvalidShake()
            block.removeFromParent()
            return false
        }

        block.activatePhysics()
        placedBlocks.append(block)
        blocksPlaced += 1
        queueIndex += selectedQueueOffset + 1
        rotationSteps = 0
        selectedQueueOffset = 0
        placementCooldownUntil = CACurrentMediaTime() + placementCooldown

        ghostBlock?.removeFromParent()
        ghostBlock = nil
        lastGhostPosition = nil

        HapticsManager.shared.blockPlaced()
        AudioManager.shared.playImpact(for: spec.material)
        gameDelegate?.sceneDidPlaceBlock()
        publishState()
        return true
    }

    func isReadyForPlacement() -> Bool {
        !gameEnded && !gamePaused && CACurrentMediaTime() >= placementCooldownUntil && currentSpec() != nil
    }

    private func currentSpec() -> BlockSpec? {
        let specs = level.blockSpecs
        let index = queueIndex + selectedQueueOffset
        guard index < specs.count else { return nil }
        return specs[index]
    }

    private func isValidPlacement(for block: BlockNode?) -> Bool {
        guard let block else { return false }
        guard blocksPlaced < level.maxBlocks else { return false }

        let frame = block.calculateAccumulatedFrame()
        let margin: CGFloat = 4
        if frame.minX < platform.leftBound - margin { return false }
        if frame.maxX > platform.rightBound + margin { return false }
        if frame.minY < platform.topY - 10 { return false }

        for other in placedBlocks {
            if frame.insetBy(dx: -2, dy: -2).intersects(other.calculateAccumulatedFrame()) {
                return false
            }
        }
        return true
    }

    func pause() {
        gamePaused = true
        physicsWorld.speed = 0
        gravityController.stop()
    }

    func resume() {
        gamePaused = false
        physicsWorld.speed = 1
        gravityController.start()
        lastTime = 0
    }

    func retry() {
        gameEnded = false
        gamePaused = false
        physicsWorld.speed = 1
        configure(level: level, gravityController: gravityController)
        setupScene()
    }

    private func triggerWin() {
        guard !gameEnded else { return }
        gameEnded = true
        physicsWorld.speed = 0
        gravityController.stop()
        spawnConfetti()

        var stars = 1
        if blocksPlaced <= level.parBlocks { stars += 1 }
        if !anyBlockCrossedFailLine { stars += 1 }

        earnedStars = stars
        HapticsManager.shared.levelComplete()
        AudioManager.shared.playWin()
        gameDelegate?.sceneDidWin(stars: stars)
        publishState(stars: stars)
    }

    private func triggerOutOfBlocks() {
        guard !gameEnded else { return }
        gameEnded = true
        physicsWorld.speed = 0
        gravityController.stop()
        HapticsManager.shared.levelFailed()
        gameDelegate?.sceneDidRunOutOfBlocks()
        publishState(outOfBlocks: true)
    }

    private func triggerFail() {
        guard !gameEnded else { return }
        gameEnded = true
        physicsWorld.speed = 0.5
        HapticsManager.shared.collapse()
        AudioManager.shared.playFail()

        run(.wait(forDuration: 0.35)) { [weak self] in
            guard let self else { return }
            self.physicsWorld.speed = 0
            self.gravityController.stop()
            HapticsManager.shared.levelFailed()
            self.gameDelegate?.sceneDidFail()
            self.publishState(failed: true)
        }
    }

    private func spawnConfetti() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 120
        emitter.numParticlesToEmit = 200
        emitter.particleLifetime = 3
        emitter.particleSpeed = 180
        emitter.particleSpeedRange = 80
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.12
        emitter.particleScaleRange = 0.06
        emitter.particleColorBlendFactor = 1
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor.systemYellow, SKColor.systemPink, SKColor.systemTeal, SKColor.systemOrange
            ],
            times: [0, 0.33, 0.66, 1]
        )
        emitter.position = CGPoint(x: cameraNode.position.x, y: platform.topY + heightTracker.currentHeight)
        emitter.zPosition = 100
        addChild(emitter)
        confettiEmitter = emitter
        run(.wait(forDuration: 3)) { emitter.removeFromParent() }
    }

    private func publishState(stars: Int = 0, failed: Bool = false, outOfBlocks: Bool = false) {
        let resolvedStars = stars > 0 ? stars : earnedStars
        var phase: GamePhase = .playing
        if failed { phase = .failed }
        else if outOfBlocks { phase = .outOfBlocks }
        else if resolvedStars > 0 { phase = .won(stars: resolvedStars) }
        else if gamePaused { phase = .paused }

        let state = GameSessionState(
            phase: phase,
            currentHeight: Double(heightTracker.currentHeight).rounded(),
            targetHeight: level.targetHeight,
            holdProgress: (heightTracker.holdProgress / level.holdDuration * 20).rounded() / 20,
            holdDuration: level.holdDuration,
            blocksPlaced: blocksPlaced,
            maxBlocks: level.maxBlocks,
            windStrength: windSystem.currentStrength,
            windDirection: windSystem.direction,
            gustWarning: windSystem.gustWarning,
            queueIndex: queueIndex,
            rotationSteps: rotationSteps,
            selectedQueueOffset: selectedQueueOffset,
            anyBlockCrossedFailLine: anyBlockCrossedFailLine,
            nearFail: nearFail,
            starsEarned: resolvedStars
        )
        gameDelegate?.sceneDidUpdateState(state)
    }

    func selectQueueOffset(_ offset: Int) {
        guard offset >= 0, queueIndex + offset < level.blockSpecs.count else { return }
        selectedQueueOffset = offset
        rotationSteps = 0
        ghostBlock?.removeFromParent()
        ghostBlock = nil
        lastGhostPosition = nil
        publishState()
    }
}

private extension TowerScene {
    static func makeParticleTexture() -> SKTexture {
        let size = CGSize(width: 8, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }
}

extension TowerScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node as? BlockNode ?? contact.bodyB.node as? BlockNode,
              let nodeB = contact.bodyB.node as? BlockNode ?? contact.bodyA.node as? BlockNode else { return }

        if nodeA.spec.material == .rubber || nodeB.spec.material == .rubber {
            nodeA.physicsBody?.friction = max(nodeA.physicsBody?.friction ?? 0, 0.9)
            nodeB.physicsBody?.friction = max(nodeB.physicsBody?.friction ?? 0, 0.9)
        }
        if nodeA.spec.material == .ice && nodeB.spec.material == .ice {
            nodeA.physicsBody?.friction = 0.02
            nodeB.physicsBody?.friction = 0.02
        }
    }
}
