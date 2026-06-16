import Foundation
import SpriteKit

struct HeightTracker {
    let platformTopY: CGFloat
    let targetHeightAbovePlatform: CGFloat
    let holdDuration: TimeInterval
    let failLineY: CGFloat

    private(set) var currentHeight: CGFloat = 0
    private(set) var holdProgress: TimeInterval = 0
    private(set) var reachedTarget = false
    private(set) var belowTargetSince: TimeInterval?
    private var lastUpdateTime: TimeInterval?

    private var targetAbsoluteY: CGFloat {
        platformTopY + targetHeightAbovePlatform
    }

    init(
        platformTopY: CGFloat,
        targetHeightAbovePlatform: CGFloat,
        holdDuration: TimeInterval,
        failLineY: CGFloat
    ) {
        self.platformTopY = platformTopY
        self.targetHeightAbovePlatform = targetHeightAbovePlatform
        self.holdDuration = holdDuration
        self.failLineY = failLineY
    }

    mutating func reset() {
        currentHeight = 0
        holdProgress = 0
        reachedTarget = false
        belowTargetSince = nil
        lastUpdateTime = nil
    }

    mutating func update(blocks: [BlockNode], time: TimeInterval) -> HeightUpdateResult {
        let delta = lastUpdateTime.map { time - $0 } ?? 0
        lastUpdateTime = time

        if blocks.isEmpty {
            currentHeight = 0
            holdProgress = 0
            reachedTarget = false
            return .inProgress
        }

        let towerTopY = measureTowerTop(from: blocks)
        currentHeight = max(0, towerTopY - platformTopY)

        if towerTopY >= targetAbsoluteY {
            reachedTarget = true
            belowTargetSince = nil
            holdProgress += delta
            if holdProgress >= holdDuration {
                return .won
            }
            return .holding(progress: holdProgress / holdDuration)
        }

        if reachedTarget {
            if belowTargetSince == nil {
                belowTargetSince = time
            } else if let start = belowTargetSince, time - start > 1.0 {
                return .failedDroppedBelow
            }
        } else {
            holdProgress = 0
        }

        return .inProgress
    }

    /// Ignore blocks that fell off or are flying upward from a bounce.
    private func measureTowerTop(from blocks: [BlockNode]) -> CGFloat {
        let contributing = blocks.filter { contributesToTowerHeight($0) }
        let source = contributing.isEmpty ? blocks : contributing
        return source.map { $0.calculateAccumulatedFrame().maxY }.max() ?? platformTopY
    }

    private func contributesToTowerHeight(_ block: BlockNode) -> Bool {
        let frame = block.calculateAccumulatedFrame()
        guard frame.minY > platformTopY - 20 else { return false }
        guard let body = block.physicsBody else { return true }
        let speed = hypot(body.velocity.dx, body.velocity.dy)
        return speed < 120
    }

    func blockFailed(_ block: BlockNode, platform: PlatformNode) -> Bool {
        let frame = block.calculateAccumulatedFrame()
        if frame.maxY < failLineY { return true }
        if frame.minY < platform.failLineY { return true }
        let margin: CGFloat = 20
        if frame.maxX < platform.leftBound - margin { return true }
        if frame.minX > platform.rightBound + margin { return true }
        return false
    }
}

enum HeightUpdateResult: Equatable {
    case inProgress
    case holding(progress: Double)
    case won
    case failedDroppedBelow
}
