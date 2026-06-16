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

    private var showsModal: Bool {
        isPausePresented || state.phase != .playing
    }

    var body: some View {
        ZStack {
            if showsModal {
                modalContent
            } else {
                VStack(spacing: 0) {
                    levelInfoBar
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var levelInfoBar: some View {
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
            .allowsHitTesting(false)

            Spacer()
                .allowsHitTesting(false)

            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var modalContent: some View {
        if isPausePresented {
            overlayCard(title: "Paused", message: "Take a breath.") {
                Button("Resume", action: onResume)
                    .buttonStyle(.borderedProminent)
                Button("Retry", action: onRetry)
                Button("Levels", action: onMenu)
            }
        } else if case .won(let stars) = state.phase {
            overlayCard(title: "Level Complete!", message: "Nice build.") {
                StarRatingView(stars: stars, maxStars: 3, size: 28)
                Button("Next Level", action: onNext)
                    .buttonStyle(.borderedProminent)
                Button("Retry", action: onRetry)
                Button("Levels", action: onMenu)
            }
        } else if case .failed = state.phase {
            overlayCard(title: "Tower Fell", message: "Try a wider base or grippy rubber.") {
                Button("Retry", action: onRetry)
                    .buttonStyle(.borderedProminent)
                Button("Levels", action: onMenu)
            }
        }
    }

    @ViewBuilder
    private func overlayCard(title: String, message: String, @ViewBuilder actions: () -> some View) -> some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
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
