import SpriteKit
import SwiftUI

struct SpriteKitView: UIViewRepresentable {
    let level: LevelConfig
    @ObservedObject var session: GameSession
    @ObservedObject var gravityController: GravityController
    var onSceneReady: (SKView, TowerSceneProtocol) -> Void

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.isMultipleTouchEnabled = false
        view.showsFPS = false
        view.showsNodeCount = false
        view.preferredFramesPerSecond = 60

        let scene = TowerScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        scene.gameDelegate = context.coordinator
        scene.configure(level: level, gravityController: gravityController)
        context.coordinator.scene = scene
        context.coordinator.skView = view
        view.presentScene(scene)
        DispatchQueue.main.async {
            onSceneReady(view, scene)
        }
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        context.coordinator.session = session
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(session: session)
    }

    @MainActor
    final class Coordinator: NSObject, TowerSceneDelegate {
        var session: GameSession
        weak var scene: TowerScene?
        weak var skView: SKView?

        init(session: GameSession) {
            self.session = session
        }

        func sceneDidUpdateState(_ state: GameSessionState) {
            session.updateFromScene(state)
        }

        func sceneDidPlaceBlock() {}

        func sceneDidWin(stars: Int) {
            var state = session.state
            state.phase = .won(stars: stars)
            state.starsEarned = stars
            session.updateFromScene(state)
        }

        func sceneDidFail() {
            var state = session.state
            state.phase = .failed
            session.updateFromScene(state)
        }

        func sceneDidRunOutOfBlocks() {
            var state = session.state
            state.phase = .outOfBlocks
            session.updateFromScene(state)
        }

        func sceneDidWarnGust() {}

        func sceneDidNearFail(_ near: Bool) {
            var state = session.state
            state.nearFail = near
            session.updateFromScene(state)
        }
    }
}
