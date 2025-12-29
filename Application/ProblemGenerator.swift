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

/// 難易度に応じた問題を生成する
public struct ProblemGenerator: Sendable {
    
    // MARK: - 利用可能なゲート
    
    /// 問題生成に使うゲート
    private let availableGates: [QuantumGate] = [.x, .y, .z, .h, .s, .t]
    
    // MARK: - 問題生成
    
    /// 難易度に応じたランダムな問題を生成
    /// - Parameter difficulty: 解いた問題数（0から増加）
    public func generateProblem(difficulty: Int) -> Problem {
        return generateRandomProblem(difficulty: difficulty)
    }
    
    // MARK: - ランダム問題生成
    
    /// ランダムな問題を生成
    private func generateRandomProblem(difficulty: Int) -> Problem {
        // ランダムに2〜5ゲートの問題を生成
        let gateCount = Int.random(in: 2...5)
        
        // ランダムなゲート列を生成
        var gates: [QuantumGate] = []
        for _ in 0..<gateCount {
            // 同じゲートが連続しないようにする（X→Xは意味がない等）
            var gate: QuantumGate
            repeat {
                gate = availableGates.randomElement()!
            } while gates.last == gate
            
            gates.append(gate)
        }
        
        // ゲート列を |0⟩ に適用してターゲット状態を得る
        let targetState = gates.reduce(QuantumState.zero) { state, gate in
            gate.apply(to: state)
        }
        
        // 自明な解（|0⟩のまま）を避ける
        if targetState.fidelity(with: .zero) > 0.99 {
            return generateRandomProblem(difficulty: difficulty)  // やり直し
        }
        
        return Problem(
            targetState: targetState,
            targetBlochVector: BlochVector(from: targetState),
            minimumGates: gates.count,
            referenceSolution: gates,
            difficulty: difficulty
        )
    }
}
