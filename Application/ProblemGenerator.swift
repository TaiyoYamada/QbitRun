// SPDX-License-Identifier: MIT
// Application/ProblemGenerator.swift
// 問題（ターゲット状態）を生成する

import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 問題生成の仕組み
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ゲームの「問題」= ターゲット量子状態
// プレイヤーは |0⟩ からゲートを使ってこの状態を作る
//
// 良い問題の条件:
// 1. 解けること（いくつかのゲートで到達可能）
// 2. 簡単すぎないこと（最小1ゲート以上）
// 3. 段階的に難易度が上がること
//
// 実装アプローチ:
// 「ランダムなゲート列を適用した結果」をターゲットにする
// → 必ず解が存在する（逆向きに適用すれば戻れる）
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - 問題

/// ゲームの1問を表す構造体
public struct Problem: Sendable {
    /// 開始する量子状態（ここからスタート）
    public let startState: QuantumState
    
    /// 開始のブロッホベクトル（可視化用）
    public let startBlochVector: BlochVector
    
    /// 目標とする量子状態
    public let targetState: QuantumState
    
    /// 目標のブロッホベクトル（可視化用）
    public let targetBlochVector: BlochVector
    
    /// 最小必要ゲート数（ボーナス計算用）
    public let minimumGates: Int
    
    /// 正解の一例（参考用、デバッグ用）
    public let referenceSolution: [QuantumGate]
    
    /// 難易度（0から始まり増加）
    public let difficulty: Int
}

// MARK: - 問題生成器

/// ブロッホ球の主要状態をターゲットにした問題を生成する
public struct ProblemGenerator: Sendable {
    
    // MARK: - 使用可能な状態
    
    /// 開始・終了状態として使用可能な量子状態
    /// ブロッホ球の主要10状態
    private let availableStates: [QuantumState] = [
        .zero, .one,                    // Z軸（北極・南極）
        .plus, .minus,                  // X軸
        .plusI, .minusI,                // Y軸
        .t45, .t135, .t225, .t315       // 45度刻みの位相
    ]
    
    /// 直前の問題を記録（同じ問題の連続を防ぐ）
    private nonisolated(unsafe) static var lastProblemKey: String?
    
    // MARK: - 問題生成
    
    /// 難易度に応じた問題を生成
    /// - Parameters:
    ///   - gameDifficulty: ゲーム難易度（Easy/Hard）
    ///   - problemNumber: 問題番号（0から増加）
    public func generateProblem(gameDifficulty: GameDifficulty, problemNumber: Int) -> Problem {
        return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber)
    }
    
    // MARK: - ランダム問題生成
    
    /// ランダムな問題を生成
    private func generateRandomProblem(gameDifficulty: GameDifficulty, problemNumber: Int, retryCount: Int = 0) -> Problem {
        // 無限ループ防止
        guard retryCount < 50 else {
            return createFallbackProblem(problemNumber: problemNumber)
        }
        
        // 開始状態を決定
        let startState: QuantumState
        switch gameDifficulty {
        case .easy:
            // Easy: 常に |0⟩ から開始
            startState = .zero
        case .hard:
            // Hard: ランダムな状態から開始
            startState = availableStates.randomElement()!
        }
        
        // 終了状態をランダムに選択
        let targetState = availableStates.randomElement()!
        
        // 同じ状態は避ける
        if startState.fidelity(with: targetState) > 0.99 {
            return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, retryCount: retryCount + 1)
        }
        
        // 直前と同じ問題（開始・終了ペア）を避ける
        let problemKey = "\(startState.probabilityZero)->\(targetState.probabilityZero)"
        if let lastKey = ProblemGenerator.lastProblemKey, lastKey == problemKey {
            return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, retryCount: retryCount + 1)
        }
        
        // 今回の問題を記録
        ProblemGenerator.lastProblemKey = problemKey
        
        return Problem(
            startState: startState,
            startBlochVector: BlochVector(from: startState),
            targetState: targetState,
            targetBlochVector: BlochVector(from: targetState),
            minimumGates: 1,
            referenceSolution: [],
            difficulty: problemNumber
        )
    }
    
    /// フォールバック問題
    private func createFallbackProblem(problemNumber: Int) -> Problem {
        return Problem(
            startState: .zero,
            startBlochVector: .zero,
            targetState: .one,
            targetBlochVector: .one,
            minimumGates: 1,
            referenceSolution: [.x],
            difficulty: problemNumber
        )
    }
}
