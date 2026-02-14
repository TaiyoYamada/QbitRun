import Foundation

// MARK: - スコアエントリ

/// 1回のゲーム結果を表す
public struct ScoreEntry: Sendable, Codable, Identifiable, Hashable, Equatable {
    /// 一意の識別子
    public let id: UUID
    
    /// 合計スコア
    public let score: Int
    
    /// 解いた問題数
    public let problemsSolved: Int
    
    /// ボーナスポイント合計
    public let bonusPoints: Int
    
    /// 達成日時
    public let date: Date
    
    /// ゲームの難易度
    public let difficulty: GameDifficulty
    
    // MARK: - イニシャライザ
    
    public init(
        id: UUID = UUID(),
        score: Int,
        problemsSolved: Int,
        bonusPoints: Int = 0,
        date: Date = Date(),
        difficulty: GameDifficulty = .easy
    ) {
        self.id = id
        self.score = score
        self.problemsSolved = problemsSolved
        self.bonusPoints = bonusPoints
        self.date = date
        self.difficulty = difficulty
    }
}
