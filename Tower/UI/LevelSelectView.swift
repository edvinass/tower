import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    private let loader = LevelLoader.shared
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: sizeClass == .regular ? 5 : 3)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(loader.worlds, id: \.world) { world in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(world.title)
                                .font(.title2.bold())
                                .padding(.horizontal, 4)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(world.levels) { level in
                                    LevelCell(
                                        level: level,
                                        stars: appModel.progressStore.stars(for: level.levelId),
                                        isUnlocked: appModel.progressStore.isUnlocked(level)
                                    ) {
                                        AudioManager.shared.playUIClick()
                                        appModel.playLevel(level)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: sizeClass == .regular ? 700 : .infinity)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Levels")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Menu") {
                        appModel.showMenu()
                    }
                }
            }
        }
    }
}

private struct LevelCell: View {
    let level: LevelConfig
    let stars: Int
    let isUnlocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isUnlocked ? Color(red: 0.25, green: 0.45, blue: 0.72) : Color.gray.opacity(0.35))
                        .frame(height: 64)

                    if isUnlocked {
                        Text("\(level.levelId)")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                StarRatingView(stars: stars, maxStars: 3, size: 10)

                Text(level.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}
