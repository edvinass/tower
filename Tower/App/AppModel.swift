import Foundation
import SwiftUI

enum AppScreen: Equatable {
    case menu
    case levelSelect
    case game(LevelConfig)
}

@MainActor
final class AppModel: ObservableObject {
    @Published var screen: AppScreen = .menu
    @Published var progressStore = ProgressStore()

    func playLevel(_ level: LevelConfig) {
        screen = .game(level)
    }

    func showLevelSelect() {
        screen = .levelSelect
    }

    func showMenu() {
        screen = .menu
    }
}
