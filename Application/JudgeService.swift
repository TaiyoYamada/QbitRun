// SPDX-License-Identifier: MIT
// Application/JudgeService.swift
// 回答の正誤判定サービス

import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 正解判定の仕組み
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 量子状態の「一致」をどう判定するか？
//
// 方法1: ベクトル成分の完全一致
//   → 浮動小数点誤差で困る   
//
// 方法2: フィデリティ（忠実度）を使う ← 採用
//   フィデリティ = |⟨target|current⟩|²
//   - 1.0 = 完全一致
//   - 0.0 = 直交（まったく違う）
//   - 0.95以上なら「正解」とする
//
// なぜ0.95？
//   - 数値誤差を許容
//   - プレイヤーが「近いけど違う」状態に落ち着かないようにする
//     （0.9だと偶然の接近で正解になりやすい）
//   - 0.95は「ほぼ一致」を意味する
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - 判定結果

/// 正誤判定の結果
public struct JudgeResult: Sendable {
    /// 正解かどうか
    public let isCorrect: Bool
    
    /// フィデリティ値（0〜1）
    public let fidelity: Double
    
    /// フィードバックメッセージ
    public let message: String
}

// MARK: - 判定サービス

/// プレイヤーの回答を判定するサービス
public struct JudgeService: Sendable {
    
    // MARK: - 定数
    
    /// 正解とみなすフィデリティの閾値
    /// 0.95 = 95%以上の忠実度で正解
    private let fidelityThreshold: Double = 0.95
    
    // MARK: - 判定
    
    /// 回路を判定
    /// - Parameters:
    ///   - playerCircuit: プレイヤーが作った回路
    ///   - startState: 開始の量子状態
    ///   - targetState: 目標の量子状態
    /// - Returns: 判定結果
    public func judge(playerCircuit: Circuit, startState: QuantumState, targetState: QuantumState) -> JudgeResult {
        // 開始状態に回路を適用
        let resultState = playerCircuit.apply(to: startState)
        
        // フィデリティを計算
        let fidelity = resultState.fidelity(with: targetState)
        
        // 判定
        let isCorrect = fidelity >= fidelityThreshold
        
        // フィードバックメッセージ
        let message = generateMessage(fidelity: fidelity, isCorrect: isCorrect)
        
        return JudgeResult(
            isCorrect: isCorrect,
            fidelity: fidelity,
            message: message
        )
    }
    
    /// 状態を直接判定（回路なしで）
    public func judge(currentState: QuantumState, targetState: QuantumState) -> JudgeResult {
        let fidelity = currentState.fidelity(with: targetState)
        let isCorrect = fidelity >= fidelityThreshold
        let message = generateMessage(fidelity: fidelity, isCorrect: isCorrect)
        
        return JudgeResult(
            isCorrect: isCorrect,
            fidelity: fidelity,
            message: message
        )
    }
    
    // MARK: - フィードバック生成
    
    /// フィデリティに応じたメッセージを生成
    private func generateMessage(fidelity: Double, isCorrect: Bool) -> String {
        if isCorrect {
            return "正解！"
        }
        
        // 進捗に応じたアドバイス
        switch fidelity {
        case 0.9..<1.0:
            return "あと少し！"
        case 0.7..<0.9:
            return "近づいている..."
        case 0.5..<0.7:
            return "方向は合っているかも"
        case 0.3..<0.5:
            return "まだ遠い"
        default:
            return "もっとゲートを試してみよう"
        }
    }
}
