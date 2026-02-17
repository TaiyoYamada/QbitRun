import Foundation

@Observable
@MainActor
final class ResultViewModel {

    private let scoreRepository: ScoreRepository

    let score: ScoreEntry

    private(set) var rank: Int?

    private(set) var isLoading: Bool = true

    init(score: ScoreEntry, scoreRepository: ScoreRepository = ScoreRepository()) {
        self.score = score
        self.scoreRepository = scoreRepository
    }

    func loadResults() async {
        isLoading = true

        rank = await scoreRepository.saveScore(score)

        isLoading = false
    }
}
