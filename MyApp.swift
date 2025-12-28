// SPDX-License-Identifier: MIT
// MyApp.swift
// アプリのエントリーポイント

import SwiftUI

/// アプリのエントリーポイント
@main
struct QuantumGateGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// ルートコンテンツビュー
struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    private let scoreRepository = ScoreRepository()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // タイトル画面
            TitleView(
                onStart: { navigationPath.append(AppRoute.mainMenu) }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .mainMenu:
                    MainMenuView(
                        onPlayGame: { navigationPath.append(AppRoute.game) },
                        onShowRecords: { navigationPath.append(AppRoute.records) },
                        onShowHelp: { navigationPath.append(AppRoute.help) },
                        onBackToTitle: { navigationPath.removeLast() }
                    )
                    .navigationBarBackButtonHidden(true)
                    
                case .game:
                    GameView(
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
                            navigationPath.append(AppRoute.game)
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
    case game
    case result(score: ScoreEntry)
    case records
    case help
}

#Preview("App") {
    ContentView()
}
