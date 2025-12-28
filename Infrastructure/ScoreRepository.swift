// SPDX-License-Identifier: MIT
// Infrastructure/ScoreRepository.swift
// スコアの永続化（UserDefaults使用）

import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// actorとは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// Swift Concurrencyの重要な概念
//
// 問題: 複数のタスクが同時に同じデータにアクセスすると競合が起きる
// 例: タスクAが読み込み中にタスクBが書き込み → データ破損
//
// 解決: actor を使う
// - actor 内のプロパティへのアクセスは自動的に直列化される
// - 外部からアクセスする時は await が必要
// - データ競合を防ぐ仕組みが言語レベルで保証される
//
// SwiftUI相当: なし（SwiftUIは基本MainActorで動く）
// UIKit相当: DispatchQueue.sync や NSLock などに相当
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
    
    // MARK: - イニシャライザ
    
    public init(
        id: UUID = UUID(),
        score: Int,
        problemsSolved: Int,
        bonusPoints: Int = 0,
        date: Date = Date()
    ) {
        self.id = id
        self.score = score
        self.problemsSolved = problemsSolved
        self.bonusPoints = bonusPoints
        self.date = date
    }
}

// MARK: - スコアリポジトリ

/// スコアの保存・読み込みを担当
/// actor: スレッドセーフなアクセスを保証
public actor ScoreRepository {
    
    // MARK: - 定数
    
    /// UserDefaultsのキー
    private let storageKey = "quantum_gate_game_scores"
    
    /// 保存する最大スコア数
    private let maxScores = 5
    
    // MARK: - プロパティ
    
    /// UserDefaultsへの参照
    private let defaults: UserDefaults
    
    // MARK: - イニシャライザ
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    // MARK: - 保存
    
    /// スコアを保存し、ランキング順位を返す
    /// - Returns: 新しい順位（Top5に入らなければnil）
    @discardableResult
    public func saveScore(_ entry: ScoreEntry) -> Int? {
        var scores = fetchTopScores()
        
        // 追加
        scores.append(entry)
        
        // スコア降順でソート
        scores.sort { $0.score > $1.score }
        
        // Top5に制限
        scores = Array(scores.prefix(maxScores))
        
        // 保存
        saveScores(scores)
        
        // 新しいエントリの順位を返す
        if let rank = scores.firstIndex(where: { $0.id == entry.id }) {
            return rank + 1  // 1-indexed
        }
        
        return nil  // Top5に入らなかった
    }
    
    // MARK: - 読み込み
    
    /// Top5を取得（スコア降順）
    public func fetchTopScores() -> [ScoreEntry] {
        // UserDefaultsからデータ取得
        guard let data = defaults.data(forKey: storageKey) else {
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
    
    /// ハイスコアを取得
    public func highScore() -> Int {
        fetchTopScores().first?.score ?? 0
    }
    
    // MARK: - 内部メソッド
    
    /// スコアリストを保存
    private func saveScores(_ scores: [ScoreEntry]) {
        do {
            let data = try JSONEncoder().encode(scores)
            defaults.set(data, forKey: storageKey)
        } catch {
            // エンコード失敗時は何もしない
        }
    }
    
    /// 全スコアを削除（デバッグ用）
    public func clearAllScores() {
        defaults.removeObject(forKey: storageKey)
    }
}
