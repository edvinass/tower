import Foundation

@MainActor
final class LevelLoader {
    static let shared = LevelLoader()

    private(set) var allLevels: [LevelConfig] = []
    private(set) var worlds: [WorldLevels] = []

    private init() {
        loadLevels()
    }

    func loadLevels() {
        worlds = (1...6).compactMap { worldIndex in
            guard let url = Bundle.main.url(forResource: "world\(worldIndex)", withExtension: "json", subdirectory: "Levels")
                ?? Bundle.main.url(forResource: "world\(worldIndex)", withExtension: "json") else {
                return nil
            }
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(WorldLevels.self, from: data)
            } catch {
                print("Failed to load world\(worldIndex): \(error)")
                return nil
            }
        }
        allLevels = worlds.flatMap(\.levels).sorted { $0.levelId < $1.levelId }
    }

    func level(withId id: Int) -> LevelConfig? {
        allLevels.first { $0.levelId == id }
    }

    func levels(inWorld world: Int) -> [LevelConfig] {
        worlds.first { $0.world == world }?.levels ?? []
    }
}
