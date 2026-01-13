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

// MARK: - スコアリポジトリ

/// スコアの保存・読み込みを担当
/// actor: スレッドセーフなアクセスを保証
public actor ScoreRepository {
    
    // MARK: - 定数
    
    /// UserDefaultsのキーのベース
    private let storageKeyBase = "quantum_gate_game_scores"
    
    /// 保存する最大スコア数
    private let maxScores = 5
    
    // MARK: - プロパティ
    
    /// UserDefaultsへの参照
    private let defaults: UserDefaults
    
    // MARK: - イニシャライザ
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    // MARK: - ヘルパー
    
    /// 難易度別のストレージキーを取得
    private func storageKey(for difficulty: GameDifficulty) -> String {
        "\(storageKeyBase)_\(difficulty.rawValue)"
    }
    
    // MARK: - 保存
    
    /// スコアを保存し、ランキング順位を返す
    /// - Returns: 新しい順位（Top5に入らなければnil）
    @discardableResult
    public func saveScore(_ entry: ScoreEntry) -> Int? {
        let difficulty = entry.difficulty
        var scores = fetchTopScores(for: difficulty)
        
        // 追加
        scores.append(entry)
        
        // スコア降順でソート
        scores.sort { $0.score > $1.score }
        
        // Top5に制限
        scores = Array(scores.prefix(maxScores))
        
        // 保存
        saveScores(scores, for: difficulty)
        
        // 新しいエントリの順位を返す
        if let rank = scores.firstIndex(where: { $0.id == entry.id }) {
            return rank + 1  // 1-indexed
        }
        
        return nil  // Top5に入らなかった
    }
    
    // MARK: - 読み込み
    
    /// 指定された難易度のTop5を取得（スコア降順）
    public func fetchTopScores(for difficulty: GameDifficulty) -> [ScoreEntry] {
        let key = storageKey(for: difficulty)
        
        // UserDefaultsからデータ取得
        guard let data = defaults.data(forKey: key) else {
            return []
        }
        
        // JSONデコード
        do {
            let scores = try JSONDecoder().decode([ScoreEntry].self, from: data)
            return scores.sorted { $0.score > $1.score }
        } catch {
            // デコード失敗時は空配列
            return []
        }
    }
    
    /// 指定された難易度のハイスコアを取得
    public func highScore(for difficulty: GameDifficulty) -> Int {
        fetchTopScores(for: difficulty).first?.score ?? 0
    }
    
    // MARK: - 内部メソッド
    
    /// スコアリストを保存
    private func saveScores(_ scores: [ScoreEntry], for difficulty: GameDifficulty) {
        let key = storageKey(for: difficulty)
        do {
            let data = try JSONEncoder().encode(scores)
            defaults.set(data, forKey: key)
        } catch {
            // エンコード失敗時は何もしない
        }
    }
    
    /// 指定された難易度のスコアを削除（デバッグ用）
    public func clearScores(for difficulty: GameDifficulty) {
        let key = storageKey(for: difficulty)
        defaults.removeObject(forKey: key)
    }
    
    /// 全スコアを削除（デバッグ用）
    public func clearAllScores() {
        for difficulty in GameDifficulty.allCases {
            clearScores(for: difficulty)
        }
    }
}

