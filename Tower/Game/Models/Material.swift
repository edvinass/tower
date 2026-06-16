import SpriteKit
import SwiftUI

enum Material: String, Codable, CaseIterable, Identifiable {
    case wood
    case ice
    case rubber
    case metal

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var density: CGFloat {
        switch self {
        case .wood: return 1.0
        case .ice: return 0.7
        case .rubber: return 0.6
        case .metal: return 2.5
        }
    }

    var friction: CGFloat {
        switch self {
        case .wood: return 0.55
        case .ice: return 0.05
        case .rubber: return 0.95
        case .metal: return 0.35
        }
    }

    var restitution: CGFloat {
        switch self {
        case .wood: return 0.1
        case .ice: return 0.05
        case .rubber: return 0.65
        case .metal: return 0.08
        }
    }

    var dragCoefficient: CGFloat {
        switch self {
        case .wood: return 1.0
        case .ice: return 1.4
        case .rubber: return 0.9
        case .metal: return 0.5
        }
    }

    var fillColor: SKColor {
        switch self {
        case .wood: return SKColor(red: 0.55, green: 0.35, blue: 0.18, alpha: 1)
        case .ice: return SKColor(red: 0.65, green: 0.88, blue: 0.95, alpha: 0.9)
        case .rubber: return SKColor(red: 0.45, green: 0.22, blue: 0.22, alpha: 1)
        case .metal: return SKColor(red: 0.62, green: 0.68, blue: 0.75, alpha: 1)
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .wood: return Color(red: 0.55, green: 0.35, blue: 0.18)
        case .ice: return Color(red: 0.65, green: 0.88, blue: 0.95)
        case .rubber: return Color(red: 0.45, green: 0.22, blue: 0.22)
        case .metal: return Color(red: 0.62, green: 0.68, blue: 0.75)
        }
    }

    var strokeColor: SKColor {
        fillColor.withAlphaComponent(0.85).darker(by: 0.15)
    }
}

private extension SKColor {
    func darker(by amount: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: max(r - amount, 0), green: max(g - amount, 0), blue: max(b - amount, 0), alpha: a)
    }
}
