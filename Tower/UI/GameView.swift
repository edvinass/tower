import SwiftUI

struct GameView: View {
    let level: LevelConfig

    @EnvironmentObject private var appModel: AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @StateObject private var session: GameSession
    @StateObject private var gravityController = GravityController()
    @State private var sceneController: TowerSceneProtocol?
    @State private var dragLocation: CGPoint?
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
                    onSceneReady: { scene in
                        sceneController = scene
                    }
                )
                .ignoresSafeArea()

                if sizeClass == .regular {
                    regularLayout(geo: geo)
                } else {
                    compactLayout(geo: geo)
                }

                if session.state.nearFail {
                    RadialGradient(
                        colors: [.red.opacity(0.35), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(geo.size.width, geo.size.height) * 0.6
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.3), value: session.state.nearFail)
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
            .contentShape(Rectangle())
            .gesture(dragGesture(in: geo))
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

    @ViewBuilder
    private func compactLayout(geo: GeometryProxy) -> some View {
        VStack {
            HStack(alignment: .top) {
                HeightMeterView(
                    current: session.state.currentHeight,
                    target: session.state.targetHeight,
                    holdProgress: session.state.holdProgress
                )
                .frame(width: 36, height: 180)
                .padding(.leading, 12)
                .padding(.top, 8)

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    WindMeterView(
                        strength: session.state.windStrength,
                        direction: session.state.windDirection,
                        gustWarning: session.state.gustWarning
                    )
                    Button {
                        sceneController?.rotatePendingBlock()
                    } label: {
                        Image(systemName: "rotate.right")
                            .font(.title3)
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.trailing, 12)
                .padding(.top, 8)
            }

            Spacer()

            BlockQueueView(
                blocks: session.visibleQueue,
                selectedOffset: session.state.selectedQueueOffset,
                onSelect: { offset in
                    (sceneController as? TowerScene)?.selectQueueOffset(offset)
                }
            )
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func regularLayout(geo: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: 0) {
            VStack {
                HeightMeterView(
                    current: session.state.currentHeight,
                    target: session.state.targetHeight,
                    holdProgress: session.state.holdProgress
                )
                .frame(width: 48, height: 260)
                Spacer()
            }
            .frame(width: 80)
            .padding(.leading, 16)
            .padding(.top, 24)

            Spacer()

            VStack {
                WindMeterView(
                    strength: session.state.windStrength,
                    direction: session.state.windDirection,
                    gustWarning: session.state.gustWarning
                )
                Button {
                    sceneController?.rotatePendingBlock()
                } label: {
                    Label("Rotate", systemImage: "rotate.right")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .padding(.top, 12)
                Spacer()
            }
            .frame(width: 120)
            .padding(.trailing, 16)
            .padding(.top, 24)
        }

        VStack {
            Spacer()
            BlockQueueView(
                blocks: session.visibleQueue,
                selectedOffset: session.state.selectedQueueOffset,
                onSelect: { offset in
                    (sceneController as? TowerScene)?.selectQueueOffset(offset)
                }
            )
            .frame(maxWidth: 600)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func dragGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard session.state.phase == .playing else { return }
                dragLocation = value.location
                let scenePoint = convertToScene(value.location, in: geo)
                sceneController?.updateGhost(at: scenePoint)
            }
            .onEnded { value in
                guard session.state.phase == .playing else { return }
                let scenePoint = convertToScene(value.location, in: geo)
                sceneController?.placeBlock(at: scenePoint)
                sceneController?.updateGhost(at: nil)
                dragLocation = nil
            }
    }

    private func convertToScene(_ point: CGPoint, in geo: GeometryProxy) -> CGPoint {
        let sceneWidth: CGFloat = 390
        let sceneHeight: CGFloat = 844
        let x = (point.x / geo.size.width - 0.5) * sceneWidth
        let y = (0.5 - point.y / geo.size.height) * sceneHeight
        return CGPoint(x: x, y: y)
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
