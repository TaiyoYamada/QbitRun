import SwiftUI

/// ルートコンテンツビュー
struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    private let scoreRepository = ScoreRepository()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // シネマティックタイトル画面
            CinematicTitleView(
                onStart: { navigationPath.append(AppRoute.mainMenu) }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .mainMenu:
                    MainMenuView(
                        onPlayGame: { navigationPath.append(AppRoute.difficultySelect) },
                        onShowRecords: { navigationPath.append(AppRoute.records) },
                        onShowHelp: { navigationPath.append(AppRoute.help) }
                    )
                    .navigationBarBackButtonHidden(true)
                    
                case .difficultySelect:
                    DifficultySelectView(
                        onSelectDifficulty: { difficulty in
                            navigationPath.append(AppRoute.game(difficulty: difficulty))
                        },
                        onBack: { navigationPath.removeLast() }
                    )
                    .navigationBarBackButtonHidden(true)
                    
                case .game(let difficulty):
                    GameView(
                        difficulty: difficulty,
                        onGameEnd: { score in
                            navigationPath.append(AppRoute.result(score: score))
                        }
                    )
                    .navigationBarBackButtonHidden(true)
                    
                case .result(let score):
                    ResultView(
                        score: score,
                        scoreRepository: scoreRepository,
                        onPlayAgain: {
                            navigationPath.removeLast(navigationPath.count)
                            navigationPath.append(AppRoute.mainMenu)
                            navigationPath.append(AppRoute.difficultySelect)
                        },
                        onReturnToMenu: {
                            navigationPath.removeLast(navigationPath.count)
                        }
                    )
                    .navigationBarBackButtonHidden(true)
                    
                case .records:
                    RecordsView(
                        scoreRepository: scoreRepository,
                        onBack: { navigationPath.removeLast() }
                    )
                    .navigationBarBackButtonHidden(true)
                    
                case .help:
                    HelpView(onBack: { navigationPath.removeLast() })
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// 画面遷移のルート定義
enum AppRoute: Hashable {
    case mainMenu
    case difficultySelect
    case game(difficulty: GameDifficulty)
    case result(score: ScoreEntry)
    case records
    case help
}

#Preview("App") {
    ContentView()
}
