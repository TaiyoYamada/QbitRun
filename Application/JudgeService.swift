import Foundation

public struct JudgeService: Sendable {

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
