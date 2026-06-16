import SwiftUI

struct GameOverlayView: View {
    let state: GameSessionState
    let levelName: String
    let onPause: () -> Void
    let onResume: () -> Void
    let onRetry: () -> Void
    let onNext: () -> Void
    let onMenu: () -> Void
    @Binding var isPausePresented: Bool
    var gravityController: GravityController?

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(levelName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Blocks \(state.blocksPlaced)/\(state.maxBlocks)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

                Spacer()

                if state.phase == .playing {
                    Button(action: onPause) {
                        Image(systemName: "pause.fill")
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Spacer()
        }

        if isPausePresented {
            overlayCard(title: "Paused", message: "Take a breath.") {
                Button("Resume", action: onResume)
                    .buttonStyle(.borderedProminent)
                Button("Retry", action: onRetry)
                Button("Levels", action: onMenu)
            }
        }

        if case .won(let stars) = state.phase {
            overlayCard(title: "Level Complete!", message: "Nice build.") {
                StarRatingView(stars: stars, maxStars: 3, size: 28)
                Button("Next Level", action: onNext)
                    .buttonStyle(.borderedProminent)
                Button("Retry", action: onRetry)
                Button("Levels", action: onMenu)
            }
        }

        if case .failed = state.phase {
            overlayCard(title: "Tower Fell", message: "Try a wider base or grippy rubber.") {
                Button("Retry", action: onRetry)
                    .buttonStyle(.borderedProminent)
                Button("Levels", action: onMenu)
            }
        }

        #if targetEnvironment(simulator) || DEBUG
        if let gravityController {
            DebugControlsView(gravity: gravityController)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 8)
                .padding(.bottom, 100)
        }
        #endif
    }

    @ViewBuilder
    private func overlayCard(title: String, message: String, @ViewBuilder actions: () -> some View) -> some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(title)
                    .font(.title.bold())
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                VStack(spacing: 10) {
                    actions()
                }
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(32)
        }
    }
}
