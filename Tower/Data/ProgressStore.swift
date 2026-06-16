import Foundation

@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var unlockedLevelId: Int
    @Published private(set) var starsByLevel: [Int: Int]

    private let unlockedKey = "tower.unlockedLevel"
    private let starsKey = "tower.stars"

    init() {
        let defaults = UserDefaults.standard
        unlockedLevelId = max(defaults.integer(forKey: unlockedKey), 1)
        if let data = defaults.data(forKey: starsKey),
           let decoded = try? JSONDecoder().decode([Int: Int].self, from: data) {
            starsByLevel = decoded
        } else {
            starsByLevel = [:]
        }
    }

    func isUnlocked(_ level: LevelConfig) -> Bool {
        level.levelId <= unlockedLevelId
    }

    func stars(for levelId: Int) -> Int {
        starsByLevel[levelId] ?? 0
    }

    func recordCompletion(level: LevelConfig, stars: Int) {
        let previous = starsByLevel[level.levelId] ?? 0
        if stars > previous {
            starsByLevel[level.levelId] = stars
            saveStars()
        }
        if level.levelId >= unlockedLevelId {
            unlockedLevelId = min(level.levelId + 1, 30)
            UserDefaults.standard.set(unlockedLevelId, forKey: unlockedKey)
        }
    }

    func resetAll() {
        unlockedLevelId = 1
        starsByLevel = [:]
        UserDefaults.standard.set(1, forKey: unlockedKey)
        saveStars()
    }

    private func saveStars() {
        if let data = try? JSONEncoder().encode(starsByLevel) {
            UserDefaults.standard.set(data, forKey: starsKey)
        }
    }
}
