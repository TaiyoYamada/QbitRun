import Foundation

// MARK: - 判定サービス

/// プレイヤーの回答を判定するサービス
public struct JudgeService: Sendable {
    
    // MARK: - 定数
    
    /// 正解とみなすフィデリティの閾値
    /// 0.95 = 95%以上の忠実度で正解
    private let fidelityThreshold: Double = 0.95
    
    // MARK: - 判定

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
