import Foundation

/// 現在の問題と最近の出題履歴を管理し，重複を避けた新問題の生成を制御する
@Observable
@MainActor
public final class ProblemManager {

    public private(set) var currentProblem: Problem?

    private let problemGenerator = ProblemGenerator()

    private var recentProblemKeys: [String] = []

    /// 重複回避対象とする履歴数
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
