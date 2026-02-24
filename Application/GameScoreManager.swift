import Foundation

@Observable
@MainActor
public final class GameScoreManager {

    public private(set) var score: Int = 0

    public private(set) var problemsSolved: Int = 0

    public private(set) var comboCount: Int = 0

    public private(set) var lastComboBonus: Int = 0

    public private(set) var missCount: Int = 0

    private let scoreCalculator = ScoreCalculator()

    public func recordCorrectAnswer(difficulty: GameDifficulty) {
        comboCount += 1

        let result = scoreCalculator.calculate(
            difficulty: difficulty,
            comboCount: comboCount
        )

        lastComboBonus = result.comboBonus
        score += result.totalGain
        problemsSolved += 1
    }

    public func recordWrongAnswer() {
        comboCount = 0
        lastComboBonus = 0
    }

    public func reset() {
        score = 0
        problemsSolved = 0
        comboCount = 0
        lastComboBonus = 0
        missCount = 0
    }
}
