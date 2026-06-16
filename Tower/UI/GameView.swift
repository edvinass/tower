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
    @State private var isDraggingPiece = false

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

                // Playfield drag layer — only the area not covered by HUD chrome.
                playfieldDragLayer(in: geo)

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
                        isDraggingPiece = false
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
            .overlay(alignment: .top) { topHUD }
            .overlay(alignment: .bottom) { bottomQueue }
            .overlay(alignment: .trailing) {
                if sizeClass == .regular { sideHUD }
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

    private func playfieldDragLayer(in geo: GeometryProxy) -> some View {
        let topInset: CGFloat = sizeClass == .regular ? 100 : 88
        let bottomInset: CGFloat = sizeClass == .regular ? 130 : 110

        return VStack(spacing: 0) {
            Color.clear.frame(height: topInset).allowsHitTesting(false)
            Color.clear
                .contentShape(Rectangle())
                .gesture(playfieldDragGesture)
            Color.clear.frame(height: bottomInset).allowsHitTesting(false)
        }
        .allowsHitTesting(session.state.phase == .playing)
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
            queueBaseIndex: session.state.queueIndex,
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
        .padding(.horizontal, sizeClass == .regular ? 24 : 8)
        .padding(.bottom, sizeClass == .regular ? 24 : 12)
    }

    private var playfieldDragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .global)
            .onChanged { value in
                handleDragChanged(at: value.location)
            }
            .onEnded { value in
                handleDragEnded(at: value.location)
            }
    }

    private func handleDragChanged(at globalPoint: CGPoint) {
        guard session.state.phase == .playing else { return }
        isDraggingPiece = true
        let scenePoint = convertToScene(globalPoint)
        sceneController?.updateGhost(at: scenePoint)
    }

    private func handleDragEnded(at globalPoint: CGPoint) {
        guard session.state.phase == .playing else { return }
        isDraggingPiece = false

        let scenePoint = convertToScene(globalPoint)
        if sceneController?.isReadyForPlacement() == true {
            let placed = sceneController?.placeBlock(at: scenePoint) ?? false
            if !placed {
                // Keep ghost visible briefly on invalid placement so user can adjust.
                sceneController?.updateGhost(at: scenePoint)
            }
        } else {
            sceneController?.updateGhost(at: nil)
        }
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
