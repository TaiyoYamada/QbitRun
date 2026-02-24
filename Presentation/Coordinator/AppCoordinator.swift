import SwiftUI

enum AppRoute: Hashable {
    case game(difficulty: GameDifficulty, isTutorial: Bool, isReview: Bool)
    case result(score: ScoreEntry)
}

@Observable
@MainActor
final class AppCoordinator {

    var path = NavigationPath()

    let scoreRepository: any ScoreRepositoryProtocol

    let audioManager: AudioManager

    init(scoreRepository: any ScoreRepositoryProtocol, audioManager: AudioManager) {
        self.scoreRepository = scoreRepository
        self.audioManager = audioManager
    }

    func navigateToGame(difficulty: GameDifficulty, isTutorial: Bool = false, isReview: Bool = false) {
        path.append(AppRoute.game(difficulty: difficulty, isTutorial: isTutorial, isReview: isReview))
    }

    func navigateToResult(score: ScoreEntry) {
        path.append(AppRoute.result(score: score))
    }

    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }

}
