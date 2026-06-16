import Foundation

enum GamePhase: Equatable {
    case playing
    case paused
    case won(stars: Int)
    case failed
    case outOfBlocks
}

struct GameSessionState: Equatable {
    var phase: GamePhase = .playing
    var currentHeight: Double = 0
    var targetHeight: Double = 0
    var holdProgress: Double = 0
    var holdDuration: Double = 2
    var blocksPlaced: Int = 0
    var maxBlocks: Int = 20
    var windStrength: Double = 0
    var windDirection: CGFloat = 1
    var gustWarning: Bool = false
    var queueIndex: Int = 0
    var rotationSteps: Int = 0
    var selectedQueueOffset: Int = 0
    var anyBlockCrossedFailLine: Bool = false
    var nearFail: Bool = false
    var starsEarned: Int = 0
}
