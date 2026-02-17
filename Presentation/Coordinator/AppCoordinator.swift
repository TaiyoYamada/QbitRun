import SwiftUI

/// 画面遷移のルート定義
enum AppRoute: Hashable {
    case game(difficulty: GameDifficulty, isTutorial: Bool, isReview: Bool)
    case result(score: ScoreEntry)
}

/// アプリ全体のナビゲーションを管理するCoordinator
@Observable
final class AppCoordinator {
    
    // MARK: - Navigation State
    
    /// ナビゲーションパス（プログラマティックナビゲーション用）
    var path = NavigationPath()
    
    // MARK: - Dependencies
    
    /// スコアリポジトリ
    let scoreRepository: ScoreRepository
    
    /// オーディオマネージャー
    let audioManager: AudioManager
    
    // MARK: - Initialization
    
    init(scoreRepository: ScoreRepository = ScoreRepository(), audioManager: AudioManager = AudioManager()) {
        self.scoreRepository = scoreRepository
        self.audioManager = audioManager
    }
    
    // MARK: - Navigation Actions
    
    
    /// ゲーム画面へ遷移
    /// - Parameter difficulty: 選択された難易度
    /// - Parameter isTutorial: チュートリアルモードかどうか
    /// - Parameter isReview: レビューモード（チュートリアルのみ）かどうか
    func navigateToGame(difficulty: GameDifficulty, isTutorial: Bool = false, isReview: Bool = false) {
        path.append(AppRoute.game(difficulty: difficulty, isTutorial: isTutorial, isReview: isReview))
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
