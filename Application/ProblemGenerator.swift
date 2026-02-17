import Foundation

public struct ProblemGenerator: Sendable {

    private let availableStates: [QuantumState] = [
        .zero, .one,
        .plus, .minus,
        .plusI, .minusI,
        .t45, .t135, .t225, .t315
    ]

    private let expertStates: [QuantumState] = [
        .rx45, .rx_45, .rx135, .rx_135,
        .ry45, .ry_45, .ry135, .ry_135,
        .rx45_t, .rx_45_t, .rx135_t, .rx_135_t,
        .ry45_t, .ry_45_t, .ry135_t, .ry_135_t
    ]

    public func generateProblem(gameDifficulty: GameDifficulty, problemNumber: Int, recentProblemKeys: [String] = []) -> (problem: Problem, problemKey: String) {
        return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, recentProblemKeys: recentProblemKeys)
    }

    private func generateRandomProblem(gameDifficulty: GameDifficulty, problemNumber: Int, recentProblemKeys: [String], retryCount: Int = 0) -> (problem: Problem, problemKey: String) {
        guard retryCount < 50 else {
            return (createFallbackProblem(problemNumber: problemNumber), "fallback")
        }

        let startState: QuantumState
        switch gameDifficulty {
        case .easy:
            startState = .zero
        case .hard:
            startState = availableStates.randomElement()!
        case .expert:
            let allStates = availableStates + expertStates
            startState = allStates.randomElement()!
        }

        let targetState: QuantumState
        if gameDifficulty == .expert {
            let allStates = availableStates + expertStates
            targetState = allStates.randomElement()!
        } else {
            targetState = availableStates.randomElement()!
        }

        if startState.fidelity(with: targetState) > 0.99 {
            return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, recentProblemKeys: recentProblemKeys, retryCount: retryCount + 1)
        }

        let sv = BlochVector(from: startState)
        let tv = BlochVector(from: targetState)
        let problemKey = String(format: "%.2f,%.2f,%.2f->%.2f,%.2f,%.2f", sv.x, sv.y, sv.z, tv.x, tv.y, tv.z)
        if recentProblemKeys.contains(problemKey) {
            return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, recentProblemKeys: recentProblemKeys, retryCount: retryCount + 1)
        }

        let problem = Problem(
            startState: startState,
            startBlochVector: BlochVector(from: startState),
            targetState: targetState,
            targetBlochVector: BlochVector(from: targetState),
            minimumGates: 1,
            referenceSolution: [],
            difficulty: problemNumber
        )

        return (problem, problemKey)
    }

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
