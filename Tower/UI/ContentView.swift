import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            switch appModel.screen {
            case .menu:
                MenuView()
            case .levelSelect:
                LevelSelectView()
            case .game(let level):
                GameView(level: level)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appModel.screen)
    }
}

private struct MenuView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.35, green: 0.55, blue: 0.85), Color(red: 0.55, green: 0.78, blue: 0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: sizeClass == .regular ? 36 : 28) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: sizeClass == .regular ? 72 : 56))
                        .foregroundStyle(.white.opacity(0.95))
                        .shadow(radius: 8)

                    Text("TOWER")
                        .font(.system(size: sizeClass == .regular ? 56 : 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Stack. Balance. Reach the sky.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer()

                VStack(spacing: 14) {
                    Button {
                        AudioManager.shared.playUIClick()
                        appModel.showLevelSelect()
                    } label: {
                        Text("Play")
                            .font(.title3.bold())
                            .frame(maxWidth: sizeClass == .regular ? 320 : .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.2, green: 0.45, blue: 0.75))

                    if let first = LevelLoader.shared.allLevels.first {
                        Button("Quick Start") {
                            AudioManager.shared.playUIClick()
                            appModel.playLevel(first)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: sizeClass == .regular ? 500 : .infinity)
        }
    }
}
