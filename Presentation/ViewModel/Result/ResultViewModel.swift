// SPDX-License-Identifier: MIT
// Presentation/ViewModel/Result/ResultViewModel.swift
// リザルト画面のViewModel

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
    
    /// トップスコア一覧
    private(set) var topScores: [ScoreEntry] = []
    
    /// ローディング中かどうか
    private(set) var isLoading: Bool = true
    
    // MARK: - 初期化
    
    init(score: ScoreEntry, scoreRepository: ScoreRepository = ScoreRepository()) {
        self.score = score
        self.scoreRepository = scoreRepository
    }
    
    // MARK: - 計算プロパティ
    
    /// 今回のスコアがTop5に入っているか
    var isCurrentScoreInTop5: Bool {
        topScores.prefix(5).contains { $0.id == score.id }
    }
    
    /// スコアがトップスコアかどうか
    func isCurrentScore(_ entry: ScoreEntry) -> Bool {
        entry.id == score.id
    }
    
    // MARK: - アクション
    
    /// スコアを保存してランキングを取得
    func loadResults() async {
        isLoading = true
        
        // スコアを保存して順位を取得
        rank = await scoreRepository.saveScore(score)
        
        // Top5を取得
        topScores = await scoreRepository.fetchTopScores()
        
        isLoading = false
    }
}
