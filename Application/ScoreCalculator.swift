import Foundation

public struct ScoreCalculator: Sendable {

    public struct Result: Sendable {
        public let baseScore: Int
        public let comboBonus: Int
        public var totalGain: Int { baseScore + comboBonus }
    }

    public func calculate(difficulty: GameDifficulty, comboCount: Int) -> Result {
        let baseScore: Int
        switch difficulty {
        case .easy: baseScore = 100
        case .hard: baseScore = 500
        case .expert: baseScore = 3000
        }

        let comboBonus: Int
        if comboCount >= 2 {
            let maxBonus: Double
            switch difficulty {
            case .easy: maxBonus = 700.0
            case .hard: maxBonus = 1200.0
            case .expert: maxBonus = 3500.0
            }
            let k: Double = 0.5

            let midpoint: Double
            switch difficulty {
            case .easy: midpoint = 8.0
            case .hard: midpoint = 6.0
            case .expert: midpoint = 4.0
            }
            let x = Double(comboCount)

            let sigmoidValue = 1.0 / (1.0 + exp(-k * (x - midpoint)))
            comboBonus = Int(maxBonus * sigmoidValue)
        } else {
            comboBonus = 0
        }

        return Result(baseScore: baseScore, comboBonus: comboBonus)
    }
}
