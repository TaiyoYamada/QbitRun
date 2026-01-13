import Foundation

/// リザルト画面のViewModel
@Observable
@MainActor
final class ResultViewModel {
    
    // MARK: - 依存
    
    private let scoreRepository: ScoreRepository
    
    // MARK: - 入力（スコア情報）
    
    let score: ScoreEntry
    
    // MARK: - 状態
    
    /// ランキング順位
    private(set) var rank: Int?
    
    /// ローディング中かどうか
    private(set) var isLoading: Bool = true
    
    // MARK: - 初期化
    
    init(score: ScoreEntry, scoreRepository: ScoreRepository = ScoreRepository()) {
        self.score = score
        self.scoreRepository = scoreRepository
    }
    
    // MARK: - アクション
    
    /// スコアを保存してランキングを取得
    func loadResults() async {
        isLoading = true
        
        // スコアを保存して順位を取得
        rank = await scoreRepository.saveScore(score)
        
        isLoading = false
    }
}
