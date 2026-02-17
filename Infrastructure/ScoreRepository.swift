import Foundation

public actor ScoreRepository {

    private let storageKeyBase = "quantum_gate_game_scores"

    private let maxScores = 5

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func storageKey(for difficulty: GameDifficulty) -> String {
        "\(storageKeyBase)_\(difficulty.rawValue)"
    }

    @discardableResult
    public func saveScore(_ entry: ScoreEntry) -> Int? {
        let difficulty = entry.difficulty
        var scores = fetchTopScores(for: difficulty)

        scores.append(entry)

        scores.sort { $0.score > $1.score }

        scores = Array(scores.prefix(maxScores))

        saveScores(scores, for: difficulty)

        if let rank = scores.firstIndex(where: { $0.id == entry.id }) {
            return rank + 1
        }

        return nil
    }

    public func fetchTopScores(for difficulty: GameDifficulty) -> [ScoreEntry] {
        let key = storageKey(for: difficulty)

        guard let data = defaults.data(forKey: key) else {
            return []
        }

        do {
            let scores = try JSONDecoder().decode([ScoreEntry].self, from: data)
            return scores.sorted { $0.score > $1.score }
        } catch {
            return []
        }
    }

    public func highScore(for difficulty: GameDifficulty) -> Int {
        fetchTopScores(for: difficulty).first?.score ?? 0
    }

    private func saveScores(_ scores: [ScoreEntry], for difficulty: GameDifficulty) {
        let key = storageKey(for: difficulty)
        do {
            let data = try JSONEncoder().encode(scores)
            defaults.set(data, forKey: key)
        } catch {
        }
    }

    public func clearScores(for difficulty: GameDifficulty) {
        let key = storageKey(for: difficulty)
        defaults.removeObject(forKey: key)
    }

    public func clearAllScores() {
        for difficulty in GameDifficulty.allCases {
            clearScores(for: difficulty)
        }
    }
}

