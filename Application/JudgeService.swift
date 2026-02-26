import Foundation

/// プレイヤーの回路を目標状態と比較し，忠実度に基づいて正誤を判定するサービス
public struct JudgeService: Sendable {

    /// 浮動小数誤差を考慮して 1 - 1e-6 としている
    private let fidelityThreshold: Double = 1.0 - 1e-6

    public func judge(playerCircuit: Circuit, startState: QuantumState, targetState: QuantumState) -> JudgeResult {
        let resultState = playerCircuit.apply(to: startState)

        let fidelity = resultState.fidelity(with: targetState)

        let isCorrect = fidelity >= fidelityThreshold

        return JudgeResult(
            isCorrect: isCorrect,
            fidelity: fidelity
        )
    }
}
