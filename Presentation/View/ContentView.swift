import SwiftUI

/// ルートコンテンツビュー
struct ContentView: View {
    /// ナビゲーションCoordinator
    @State private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // シネマティックタイトル画面
            CinematicTitleView(
                onStart: { coordinator.navigateToMainMenu() }
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
        case .mainMenu:
            MainMenuView(
                onPlayGame: { coordinator.navigateToDifficultySelect() },
                onShowRecords: { coordinator.navigateToRecords() },
                onShowHelp: { coordinator.navigateToHelp() }
            )
            .navigationBarBackButtonHidden(true)
            
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
            
        case .records:
            RecordsView(
                scoreRepository: coordinator.scoreRepository,
                onBack: { coordinator.goBack() }
            )
            .navigationBarBackButtonHidden(true)
            
        case .help:
            HelpView(onBack: { coordinator.goBack() })
                .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview("App") {
    ContentView()
}
