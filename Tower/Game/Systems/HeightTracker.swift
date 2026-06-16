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

        let stackedBlocks = blocks.filter { isStackedOnTower($0) }

        if stackedBlocks.isEmpty {
            currentHeight = 0
            if reachedTarget {
                holdProgress = max(0, holdProgress - delta)
            } else {
                holdProgress = 0
            }
            return .inProgress
        }

        let towerTopY = stackedBlocks.map { $0.calculateAccumulatedFrame().maxY }.max() ?? platformTopY
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
            // Only penalize a meaningful drop, not wobble or a settling bounce.
            let dropBelowTarget = targetAbsoluteY - towerTopY
            if dropBelowTarget > targetHeightAbovePlatform * 0.35 {
                if belowTargetSince == nil {
                    belowTargetSince = time
                } else if let start = belowTargetSince, time - start > 1.5 {
                    return .failedDroppedBelow
                }
            } else {
                belowTargetSince = nil
                holdProgress = max(0, holdProgress - delta * 0.5)
            }
        } else {
            holdProgress = 0
        }

        return .inProgress
    }

    /// Blocks still part of the tower (on or above the platform).
    private func isStackedOnTower(_ block: BlockNode) -> Bool {
        let frame = block.calculateAccumulatedFrame()
        return frame.maxY > platformTopY - 15
    }

    func blockFailed(_ block: BlockNode, platform: PlatformNode) -> Bool {
        let frame = block.calculateAccumulatedFrame()

        // Entire block fell well below the platform.
        if frame.maxY < platform.topY - 25 {
            return true
        }

        // Block slid off the side only counts if it has also dropped near the fail line.
        let sideMargin: CGFloat = 45
        let offPlatformX = frame.maxX < platform.leftBound - sideMargin
            || frame.minX > platform.rightBound + sideMargin
        if offPlatformX && frame.maxY < platform.topY + 5 {
            return true
        }

        return false
    }
}

enum HeightUpdateResult: Equatable {
    case inProgress
    case holding(progress: Double)
    case won
    case failedDroppedBelow
}
