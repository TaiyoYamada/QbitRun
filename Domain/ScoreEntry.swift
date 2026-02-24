import Foundation

public struct ScoreEntry: Sendable, Codable, Identifiable, Hashable, Equatable {
    public let id: UUID

    public let score: Int

    public let problemsSolved: Int

    public let date: Date

    public let difficulty: GameDifficulty

    public init(
        id: UUID = UUID(),
        score: Int,
        problemsSolved: Int,

        date: Date = Date(),
        difficulty: GameDifficulty = .easy
    ) {
        self.id = id
        self.score = score
        self.problemsSolved = problemsSolved

        self.date = date
        self.difficulty = difficulty
    }
}
