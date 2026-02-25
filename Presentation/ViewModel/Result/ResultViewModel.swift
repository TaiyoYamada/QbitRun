import Foundation

@Observable
@MainActor
final class ResultViewModel {

    let score: ScoreEntry

    init(score: ScoreEntry) {
        self.score = score
    }
}
