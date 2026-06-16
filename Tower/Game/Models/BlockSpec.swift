import Foundation

struct BlockSpec: Codable, Equatable, Identifiable, Hashable {
    var material: Material
    var shape: BlockShape

    var id: String { "\(material.rawValue)_\(shape.rawValue)" }

    init(material: Material, shape: BlockShape) {
        self.material = material
        self.shape = shape
    }

    init?(from token: String) {
        let parts = token.split(separator: "_").map(String.init)
        guard parts.count == 2,
              let material = Material(rawValue: parts[0]),
              let shape = BlockShape(rawValue: parts[1]) else {
            return nil
        }
        self.material = material
        self.shape = shape
    }

    var token: String { "\(material.rawValue)_\(shape.rawValue)" }
}
