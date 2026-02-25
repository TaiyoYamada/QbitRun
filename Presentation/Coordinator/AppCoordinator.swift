import SwiftUI

/// アプリのナビゲーション先を表す列挙型
enum AppRoute: Hashable {
    case game(difficulty: GameDifficulty, isTutorial: Bool, isReview: Bool)
    case result(score: ScoreEntry)
}

/// 画面遷移を一元管理するコーディネーター
@Observable
@MainActor
final class AppCoordinator {

    var path = NavigationPath()


    let audioManager: AudioManager

    init(audioManager: AudioManager) {
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
