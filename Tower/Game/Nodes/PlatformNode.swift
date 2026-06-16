import SpriteKit

final class PlatformNode: SKNode {
    let width: CGFloat
    let platformHeight: CGFloat = 24

    init(width: CGFloat) {
        self.width = width
        super.init()
        build()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build() {
        let platform = SKShapeNode(rectOf: CGSize(width: width, height: platformHeight), cornerRadius: 4)
        platform.fillColor = SKColor(red: 0.35, green: 0.32, blue: 0.28, alpha: 1)
        platform.strokeColor = SKColor(red: 0.22, green: 0.2, blue: 0.18, alpha: 1)
        platform.lineWidth = 2
        platform.position = .zero
        addChild(platform)

        let physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: width, height: platformHeight))
        physicsBody.isDynamic = false
        physicsBody.friction = 0.8
        physicsBody.restitution = 0.05
        physicsBody.categoryBitMask = PhysicsCategory.platform
        physicsBody.contactTestBitMask = PhysicsCategory.block
        physicsBody.collisionBitMask = PhysicsCategory.block
        platform.physicsBody = physicsBody

        let groundStrip = SKShapeNode(rectOf: CGSize(width: 2000, height: 40))
        groundStrip.fillColor = SKColor(red: 0.28, green: 0.45, blue: 0.32, alpha: 1)
        groundStrip.strokeColor = .clear
        groundStrip.position = CGPoint(x: 0, y: -platformHeight / 2 - 20)
        addChild(groundStrip)

        let groundBody = SKPhysicsBody(rectangleOf: CGSize(width: 2000, height: 40))
        groundBody.isDynamic = false
        groundBody.categoryBitMask = PhysicsCategory.ground
        groundBody.collisionBitMask = PhysicsCategory.block
        groundStrip.physicsBody = groundBody
    }

    var topY: CGFloat { position.y + platformHeight / 2 }
    var failLineY: CGFloat { position.y - platformHeight / 2 - 80 }
    var leftBound: CGFloat { position.x - width / 2 }
    var rightBound: CGFloat { position.x + width / 2 }
}
