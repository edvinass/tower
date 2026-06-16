import Foundation

struct HeightTracker {
    let targetHeight: CGFloat
    let holdDuration: TimeInterval
    let failLineY: CGFloat

    private(set) var currentHeight: CGFloat = 0
    private(set) var holdProgress: TimeInterval = 0
    private(set) var reachedTarget = false
    private(set) var belowTargetSince: TimeInterval?
    private var lastUpdateTime: TimeInterval?

    init(targetHeight: CGFloat, holdDuration: TimeInterval, failLineY: CGFloat) {
        self.targetHeight = targetHeight
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

        currentHeight = blocks.map { $0.calculateAccumulatedFrame().maxY }.max() ?? 0

        if currentHeight >= targetHeight {
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
