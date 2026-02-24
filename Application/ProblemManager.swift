import Foundation

@Observable
@MainActor
public final class ProblemManager {

    public private(set) var currentProblem: Problem?

    private let problemGenerator = ProblemGenerator()

    private var recentProblemKeys: [String] = []

    private let maxRecentKeys = 4

    public func generateNewProblem(difficulty: GameDifficulty, problemNumber: Int) {
        let result = problemGenerator.generateProblem(
            gameDifficulty: difficulty,
            problemNumber: problemNumber,
            recentProblemKeys: recentProblemKeys
        )
        currentProblem = result.problem
        recentProblemKeys.append(result.problemKey)
        if recentProblemKeys.count > maxRecentKeys {
            recentProblemKeys.removeFirst()
        }
    }

    public func reset() {
        currentProblem = nil
        recentProblemKeys.removeAll()
    }
}
