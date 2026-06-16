import Foundation

struct WindConfig: Codable, Equatable {
    var baseStrength: Double
    var gustFrequency: Double
    var direction: WindDirection

    enum WindDirection: String, Codable {
        case left
        case right
        case random
    }

    static let calm = WindConfig(baseStrength: 0, gustFrequency: 0, direction: .right)
    static let light = WindConfig(baseStrength: 0.25, gustFrequency: 0.1, direction: .random)
    static let medium = WindConfig(baseStrength: 0.45, gustFrequency: 0.2, direction: .random)
    static let strong = WindConfig(baseStrength: 0.7, gustFrequency: 0.35, direction: .random)
}

struct LevelConfig: Codable, Identifiable, Equatable {
    var levelId: Int
    var name: String
    var world: Int
    var targetHeight: Double
    var holdDuration: Double
    var maxBlocks: Int
    var blockQueue: [String]
    var wind: WindConfig
    var tiltSensitivity: Double
    var platformWidth: Double
    var parBlocks: Int

    var id: Int { levelId }

    var blockSpecs: [BlockSpec] {
        blockQueue.compactMap(BlockSpec.init(from:))
    }

    var displayNumber: String {
        "W\(world)-\(levelId - (world - 1) * 5)"
    }
}

struct WorldLevels: Codable {
    var world: Int
    var title: String
    var levels: [LevelConfig]
}
