import SpriteKit

final class BlockNode: SKShapeNode {
    let spec: BlockSpec
    let rotationSteps: Int
    private(set) var isPlaced = false

    private init(spec: BlockSpec, rotationSteps: Int, path: CGPath) {
        self.spec = spec
        self.rotationSteps = rotationSteps
        super.init()
        self.path = path
        self.fillColor = spec.material.fillColor
        self.strokeColor = spec.material.strokeColor
        self.lineWidth = 2
        self.glowWidth = 0.5
        self.isAntialiased = true
        configurePhysics()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func make(spec: BlockSpec, rotationSteps: Int = 0, isGhost: Bool = false) -> BlockNode {
        let size = spec.shape.unitSize
        let path = spec.shape.path(size: size, rotationSteps: rotationSteps)
        let node = BlockNode(spec: spec, rotationSteps: rotationSteps, path: path)
        if isGhost {
            node.alpha = 0.5
            node.physicsBody = nil
        }
        return node
    }

    private func configurePhysics() {
        let size = spec.shape.unitSize
        let body: SKPhysicsBody

        if spec.shape == .circle {
            body = SKPhysicsBody(circleOfRadius: size.width / 2)
        } else {
            let path = spec.shape.path(size: size, rotationSteps: rotationSteps)
            body = SKPhysicsBody(polygonFrom: path)
        }

        let material = spec.material
        body.isDynamic = false
        body.affectedByGravity = true
        body.allowsRotation = true
        body.friction = material.friction
        body.restitution = material.restitution
        body.linearDamping = material == .rubber ? 0.35 : 0.15
        body.angularDamping = 0.25
        body.density = material.density
        body.categoryBitMask = PhysicsCategory.block
        body.contactTestBitMask = PhysicsCategory.block | PhysicsCategory.platform
        body.collisionBitMask = PhysicsCategory.block | PhysicsCategory.platform | PhysicsCategory.ground
        body.usesPreciseCollisionDetection = true
        physicsBody = body
    }

    func activatePhysics() {
        isPlaced = true
        physicsBody?.isDynamic = true
        playLandingSquash()
    }

    func playLandingSquash() {
        let squash = SKAction.scaleY(to: 0.92, duration: 0.04)
        let restore = SKAction.scaleY(to: 1.0, duration: 0.08)
        run(.sequence([squash, restore]))
    }

    func playInvalidShake() {
        let left = SKAction.moveBy(x: -8, y: 0, duration: 0.04)
        let right = SKAction.moveBy(x: 16, y: 0, duration: 0.08)
        let center = SKAction.moveBy(x: -8, y: 0, duration: 0.04)
        run(.sequence([left, right, center]))
        fillColor = .red
        run(.wait(forDuration: 0.15)) { [weak self] in
            self?.fillColor = self?.spec.material.fillColor ?? .white
        }
    }

    var boundingTopY: CGFloat {
        frame.maxY + position.y - (parent?.position.y ?? 0)
    }

    var worldFrame: CGRect {
        guard let scene = scene else { return frame }
        return convert(frame, to: scene)
    }

    var exposedWidth: CGFloat {
        max(frame.width, 20)
    }
}
