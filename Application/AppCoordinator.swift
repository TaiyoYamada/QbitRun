// SPDX-License-Identifier: MIT
// Application/AppCoordinator.swift
// アプリケーション全体のナビゲーションを集中管理するCoordinator

import SwiftUI

/// 画面遷移のルート定義
enum AppRoute: Hashable {
    case game(difficulty: GameDifficulty)
    case result(score: ScoreEntry)
}

/// アプリ全体のナビゲーションを管理するCoordinator
/// @Observable マクロによりSwiftUIと自動的に連携
@Observable
final class AppCoordinator {
    
    // MARK: - Navigation State
    
    /// ナビゲーションパス（プログラマティックナビゲーション用）
    var path = NavigationPath()
    
    // MARK: - Dependencies
    
    /// スコアリポジトリ
    let scoreRepository: ScoreRepository
    
    // MARK: - Initialization
    
    init(scoreRepository: ScoreRepository = ScoreRepository()) {
        self.scoreRepository = scoreRepository
    }
    
    // MARK: - Navigation Actions
    
    
    /// ゲーム画面へ遷移
    /// - Parameter difficulty: 選択された難易度
    func navigateToGame(difficulty: GameDifficulty) {
        path.append(AppRoute.game(difficulty: difficulty))
    }
    
    /// リザルト画面へ遷移
    /// - Parameter score: ゲームスコア
    func navigateToResult(score: ScoreEntry) {
        path.append(AppRoute.result(score: score))
    }
    
    /// 一つ前の画面へ戻る
    func goBack() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// ルート（タイトル画面）へ戻る
    func popToRoot() {
        path = NavigationPath()
    }
    
}
