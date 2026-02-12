import SwiftUI

/// ルートコンテンツビュー
struct ContentView: View {
    /// ナビゲーションCoordinator
    @State private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // メインメニュー（ルートビュー）
            MainMenuView(
                onPlayGame: { coordinator.navigateToDifficultySelect() }
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
            
        case .difficultySelect:
            DifficultySelectView(
                onSelectDifficulty: { difficulty in
                    coordinator.navigateToGame(difficulty: difficulty)
                },
                onBack: { coordinator.goBack() }
            )
            .navigationBarBackButtonHidden(true)
            
        case .game(let difficulty):
            GameView(
                difficulty: difficulty,
                onGameEnd: { score in
                    coordinator.navigateToResult(score: score)
                }
            )
            .navigationBarBackButtonHidden(true)
            
        case .result(let score):
            ResultView(
                score: score,
                scoreRepository: coordinator.scoreRepository,
                onPlayAgain: { coordinator.retryFromResult() },
                onReturnToMenu: { coordinator.popToRoot() }
            )
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview("App") {
    ContentView()
}
