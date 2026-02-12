import SwiftUI

/// ルートコンテンツビュー
struct ContentView: View {
    /// ナビゲーションCoordinator
    @State private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // メインメニュー（ルートビュー）
            MainMenuView(
                onSelectMode: { difficulty in
                    coordinator.navigateToGame(difficulty: difficulty)
                }
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
                onPlayAgain: {
                    coordinator.popToRoot()
                    coordinator.navigateToGame(difficulty: score.difficulty)
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
