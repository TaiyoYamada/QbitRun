import Foundation

public protocol ScoreRepositoryProtocol: Actor {
    @discardableResult
    func saveScore(_ entry: ScoreEntry) -> Int?
    func fetchTopScores(for difficulty: GameDifficulty) -> [ScoreEntry]
    func highScore(for difficulty: GameDifficulty) -> Int
    func clearScores(for difficulty: GameDifficulty)
    func clearAllScores()
}
