// SPDX-License-Identifier: MIT
// MyApp.swift
// アプリのエントリーポイント（SwiftUI版）

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SwiftUI App構造
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// @main: アプリのエントリーポイントを示すマクロ
// App protocol: アプリ全体のライフサイクルを管理
// WindowGroup: 1つ以上のウィンドウを提供するシーン
//
// 画面遷移は NavigationStack + NavigationDestination で宣言的に記述
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
/// NavigationStackで画面遷移を管理
struct ContentView: View {
    /// ナビゲーションパス（画面遷移の状態）
    @State private var navigationPath = NavigationPath()
    
    /// スコアリポジトリ
    private let scoreRepository = ScoreRepository()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            MenuView(
                onStartGame: { navigationPath.append(AppRoute.game) },
                scoreRepository: scoreRepository
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
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
                            navigationPath.append(AppRoute.game)
                        },
                        onReturnToMenu: {
                            navigationPath.removeLast(navigationPath.count)
                        }
                    )
                    .navigationBarBackButtonHidden(true)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// 画面遷移のルート定義
enum AppRoute: Hashable {
    case game
    case result(score: ScoreEntry)
}

// MARK: - プレビュー

#Preview("App") {
    ContentView()
}
