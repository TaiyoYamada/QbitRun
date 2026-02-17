import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationStack(path: $coordinator.path) {
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
                
                if geometry.size.width > geometry.size.height {
                    LandscapeWarningView()
                }
            }
        }
    }

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
                audioManager: coordinator.audioManager,
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
