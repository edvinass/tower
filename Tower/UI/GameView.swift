import SpriteKit
import SwiftUI

struct GameView: View {
    let level: LevelConfig

    @EnvironmentObject private var appModel: AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @StateObject private var session: GameSession
    @StateObject private var gravityController = GravityController()
    @State private var sceneController: TowerSceneProtocol?
    @State private var skView: SKView?
    @State private var showPause = false

    init(level: LevelConfig) {
        self.level = level
        _session = StateObject(wrappedValue: GameSession(level: level))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SpriteKitView(
                    level: level,
                    session: session,
                    gravityController: gravityController,
                    onSceneReady: { view, scene in
                        skView = view
                        sceneController = scene
                    }
                )
                .ignoresSafeArea()
                .gesture(playfieldDragGesture)

                if session.state.nearFail {
                    RadialGradient(
                        colors: [.red.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(geo.size.width, geo.size.height) * 0.6
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }

                topHUD
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                bottomQueue
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, sizeClass == .regular ? 24 : 8)
                    .padding(.bottom, sizeClass == .regular ? 24 : 12)

                if sizeClass == .regular {
                    sideHUD
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }

                GameOverlayView(
                    state: session.state,
                    levelName: level.name,
                    onPause: {
                        showPause = true
                        sceneController?.pause()
                    },
                    onResume: {
                        showPause = false
                        sceneController?.resume()
                    },
                    onRetry: {
                        sceneController?.retry()
                        showPause = false
                    },
                    onNext: {
                        if let next = LevelLoader.shared.level(withId: level.levelId + 1) {
                            appModel.playLevel(next)
                        } else {
                            appModel.showLevelSelect()
                        }
                    },
                    onMenu: {
                        appModel.showLevelSelect()
                    },
                    isPausePresented: $showPause,
                    gravityController: gravityController
                )
            }
        }
        .onAppear {
            gravityController.tiltSensitivity = level.tiltSensitivity
        }
        .onChange(of: session.state.phase) { _, phase in
            if case .won(let stars) = phase {
                appModel.progressStore.recordCompletion(level: level, stars: stars)
            }
        }
    }

    private var topHUD: some View {
        HStack(alignment: .top) {
            HeightMeterView(
                current: session.state.currentHeight,
                target: session.state.targetHeight,
                holdProgress: session.state.holdProgress
            )
            .frame(width: sizeClass == .regular ? 48 : 36, height: sizeClass == .regular ? 220 : 160)
            .padding(.leading, sizeClass == .regular ? 16 : 12)
            .padding(.top, 8)
            .allowsHitTesting(false)

            Spacer()

            if sizeClass != .regular {
                VStack(alignment: .trailing, spacing: 8) {
                    WindMeterView(
                        strength: session.state.windStrength,
                        direction: session.state.windDirection,
                        gustWarning: session.state.gustWarning
                    )
                    .allowsHitTesting(false)

                    rotateButton
                }
                .padding(.trailing, 12)
                .padding(.top, 8)
            }
        }
    }

    private var sideHUD: some View {
        VStack(alignment: .trailing, spacing: 12) {
            WindMeterView(
                strength: session.state.windStrength,
                direction: session.state.windDirection,
                gustWarning: session.state.gustWarning
            )
            .allowsHitTesting(false)

            rotateButton
        }
        .padding(.trailing, 16)
        .padding(.top, 24)
    }

    private var rotateButton: some View {
        Button {
            sceneController?.rotatePendingBlock()
        } label: {
            Group {
                if sizeClass == .regular {
                    Label("Rotate", systemImage: "rotate.right")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                } else {
                    Image(systemName: "rotate.right")
                        .font(.title3)
                        .padding(10)
                }
            }
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private var bottomQueue: some View {
        BlockQueueView(
            blocks: session.visibleQueue,
            selectedOffset: session.state.selectedQueueOffset,
            onSelect: { offset in
                (sceneController as? TowerScene)?.selectQueueOffset(offset)
            },
            onDragChanged: { globalPoint in
                handleDragChanged(at: globalPoint)
            },
            onDragEnded: { globalPoint in
                handleDragEnded(at: globalPoint)
            }
        )
        .frame(maxWidth: sizeClass == .regular ? 600 : .infinity)
    }

    private var playfieldDragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                handleDragChanged(at: value.location)
            }
            .onEnded { value in
                handleDragEnded(at: value.location)
            }
    }

    private func handleDragChanged(at globalPoint: CGPoint) {
        guard session.state.phase == .playing else { return }
        let scenePoint = convertToScene(globalPoint)
        sceneController?.updateGhost(at: scenePoint)
    }

    private func handleDragEnded(at globalPoint: CGPoint) {
        guard session.state.phase == .playing else { return }
        let scenePoint = convertToScene(globalPoint)
        sceneController?.placeBlock(at: scenePoint)
        sceneController?.updateGhost(at: nil)
    }

    private func convertToScene(_ globalPoint: CGPoint) -> CGPoint {
        guard let skView, let scene = skView.scene else {
            return .zero
        }
        let viewPoint = skView.convert(globalPoint, from: nil)
        return scene.convertPoint(fromView: viewPoint)
    }
}

#if DEBUG
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        if let level = LevelLoader.shared.allLevels.first {
            GameView(level: level)
                .environmentObject(AppModel())
        }
    }
}
#endif
