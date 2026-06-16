import Foundation
import Combine

@MainActor
protocol TowerSceneDelegate: AnyObject {
    func sceneDidUpdateState(_ state: GameSessionState)
    func sceneDidPlaceBlock()
    func sceneDidWin(stars: Int)
    func sceneDidFail()
    func sceneDidWarnGust()
    func sceneDidNearFail(_ near: Bool)
}

@MainActor
final class GameSession: ObservableObject {
    @Published var state = GameSessionState()
    let level: LevelConfig
    weak var sceneDelegate: TowerSceneDelegate?

    init(level: LevelConfig) {
        self.level = level
        state.targetHeight = level.targetHeight
        state.holdDuration = level.holdDuration
        state.maxBlocks = level.maxBlocks
    }

    func updateFromScene(_ state: GameSessionState) {
        guard self.state != state else { return }
        self.state = state
    }

    var visibleQueue: [BlockSpec] {
        let specs = level.blockSpecs
        guard state.queueIndex < specs.count else { return [] }
        let end = min(state.queueIndex + 5, specs.count)
        return Array(specs[state.queueIndex..<end])
    }

    var selectedSpec: BlockSpec? {
        let queue = visibleQueue
        guard state.selectedQueueOffset < queue.count else { return nil }
        return queue[state.selectedQueueOffset]
    }
}
