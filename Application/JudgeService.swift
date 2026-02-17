import Foundation

public struct JudgeService: Sendable {

    private let fidelityThreshold: Double = 0.95

    public func judge(playerCircuit: Circuit, startState: QuantumState, targetState: QuantumState) -> JudgeResult {
        let resultState = playerCircuit.apply(to: startState)

        let fidelity = resultState.fidelity(with: targetState)

        let isCorrect = fidelity >= fidelityThreshold

        let message = generateMessage(fidelity: fidelity, isCorrect: isCorrect)

        return JudgeResult(
            isCorrect: isCorrect,
            fidelity: fidelity,
            message: message
        )
    }

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

    private func generateMessage(fidelity: Double, isCorrect: Bool) -> String {
        if isCorrect {
            return "正解！"
        }

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
