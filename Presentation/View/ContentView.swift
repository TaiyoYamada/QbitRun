import SwiftUI

/// ルートコンテンツビュー
struct ContentView: View {
    /// ナビゲーションCoordinator
    @State private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // メインメニュー（ルートビュー）
            MainMenuView(
                onSelectMode: { difficulty, isTutorial, isReview in
                    coordinator.navigateToGame(difficulty: difficulty, isTutorial: isTutorial, isReview: isReview)
                },
                audioManager: coordinator.audioManager
            )
            .navigationBarBackButtonHidden(true)
            .navigationDestination(for: AppRoute.self) { route in
                destinationView(for: route)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    /// ルートに対応するViewを返す
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
            
        case .game(let difficulty, let isTutorial, let isReview):
            GameView(
                difficulty: difficulty,
                isTutorial: isTutorial,
                isReviewMode: isReview,
                onGameEnd: { score in
                    coordinator.navigateToResult(score: score)
                },
                audioManager: coordinator.audioManager
            )
            .navigationBarBackButtonHidden(true)
            
        case .result(let score):
            ResultView(
                score: score,
                scoreRepository: coordinator.scoreRepository,
                audioManager: coordinator.audioManager, // [NEW]
                onPlayAgain: {
                    coordinator.popToRoot()
                    coordinator.navigateToGame(difficulty: score.difficulty, isTutorial: false)
                },
                onReturnToMenu: { coordinator.popToRoot() }
            )
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview("App") {
    ContentView()
}
