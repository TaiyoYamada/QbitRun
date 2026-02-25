import SwiftUI

struct ContentView: View {
    @State private var coordinator = AppCoordinator(audioManager: AudioManager())

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

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
                .allowsHitTesting(!isLandscape)
                .accessibilityHidden(isLandscape)
                
                if isLandscape {
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
