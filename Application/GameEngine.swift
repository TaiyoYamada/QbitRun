import Foundation

public enum GameState: Sendable {
    case ready
    case playing
    case paused
    case finished
}

@Observable
@MainActor
public final class GameEngine {
    private let gameDuration: TimeInterval = 60

    private let baseScorePerProblem = 100

    private let maxMisses = 3

    public private(set) var state: GameState = .ready

    public private(set) var remainingTime: Int = 60

    public private(set) var score: Int = 0

    public private(set) var problemsSolved: Int = 0

    public private(set) var comboCount: Int = 0

    public private(set) var lastComboBonus: Int = 0

    public private(set) var missCount: Int = 0

    public private(set) var currentProblem: Problem?

    public private(set) var currentCircuit = Circuit(maxGates: 4)

    private var maxGatesForDifficulty: Int {
        switch gameDifficulty {
        case .easy, .hard: return 4
        case .expert: return 6
        }
    }

    public private(set) var currentVector: BlochVector = .zero

    public var targetVector: BlochVector {
        guard let problem = currentProblem else { return .zero }
        return BlochVector(from: problem.targetState)
    }

    public var currentDistance: Double {
        guard let problem = currentProblem else { return 1.0 }
        let currentState = currentCircuit.apply(to: problem.startState)
        let targetState = problem.targetState
        return currentState.fidelity(with: targetState)
    }

    public private(set) var didSolveLastProblem: Bool = false

    public private(set) var finalScoreEntry: ScoreEntry?

    private var gameDifficulty: GameDifficulty = .easy

    private let problemGenerator = ProblemGenerator()

    private var recentProblemKeys: [String] = []
    private let maxRecentKeys = 4

    private let judgeService = JudgeService()

    private var timerTask: Task<Void, Never>?

    public func start(difficulty: GameDifficulty = .easy, startTimer: Bool = true) {
        guard state == .ready else { return }

        self.gameDifficulty = difficulty

        state = .playing
        remainingTime = Int(gameDuration)
        score = 0
        problemsSolved = 0
        comboCount = 0
        lastComboBonus = 0
        missCount = 0
        currentCircuit = Circuit(maxGates: maxGatesForDifficulty)
        didSolveLastProblem = false
        finalScoreEntry = nil

        generateNewProblem()

        if let problem = currentProblem {
            currentVector = problem.startBlochVector
        } else {
            currentVector = .zero
        }

        if startTimer {
            self.startTimer()
        }
    }

    public func startGameLoop() {
        guard state == .playing, timerTask == nil else { return }
        startTimer()
    }

    public func pause() {
        guard state == .playing else { return }
        state = .paused
        timerTask?.cancel()
    }

    public func resume() {
        guard state == .paused else { return }
        state = .playing
        startTimer()
    }

    public func reset() {
        timerTask?.cancel()
        state = .ready
        remainingTime = Int(gameDuration)
        score = 0
        problemsSolved = 0
        comboCount = 0
        lastComboBonus = 0
        missCount = 0
        currentCircuit = Circuit(maxGates: 4)
        currentProblem = nil
        currentVector = .zero
        didSolveLastProblem = false
        finalScoreEntry = nil
        recentProblemKeys = []
    }

    private func endGame() {
        state = .finished
        timerTask?.cancel()

        finalScoreEntry = ScoreEntry(
            score: score,
            problemsSolved: problemsSolved,
            difficulty: gameDifficulty
        )
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                guard let self = self, self.state == .playing else { break }

                self.remainingTime -= 1

                if self.remainingTime <= 0 {
                    self.endGame()
                    break
                }
            }
        }
    }

    private func generateNewProblem() {
        let result = problemGenerator.generateProblem(gameDifficulty: gameDifficulty, problemNumber: problemsSolved, recentProblemKeys: recentProblemKeys)
        currentProblem = result.problem
        recentProblemKeys.append(result.problemKey)
        if recentProblemKeys.count > maxRecentKeys {
            recentProblemKeys.removeFirst()
        }
    }

    public func addGate(_ gate: QuantumGate) {
        guard state == .playing else { return }
        guard currentCircuit.addGate(gate) else { return }

        guard let problem = currentProblem else { return }
        let currentState = currentCircuit.apply(to: problem.startState)
        currentVector = BlochVector(from: currentState)
    }

    public func removeGate(at index: Int) {
        guard state == .playing else { return }
        currentCircuit.removeGate(at: index)

        guard let problem = currentProblem else { return }
        let currentState = currentCircuit.apply(to: problem.startState)
        currentVector = BlochVector(from: currentState)
    }

    public func clearCircuit() {
        guard state == .playing else { return }
        currentCircuit.clear()
        if let problem = currentProblem {
            currentVector = problem.startBlochVector
        } else {
            currentVector = .zero
        }
    }

    public func checkCurrentState() -> Bool {
        guard let problem = currentProblem else { return false }

        let result = judgeService.judge(
            playerCircuit: currentCircuit,
            startState: problem.startState,
            targetState: problem.targetState
        )

        return result.isCorrect
    }

    public func handleCorrectAnswer() {
        guard currentProblem != nil else { return }

        comboCount += 1

        let baseScore: Int
        switch gameDifficulty {
        case .easy: baseScore = 100
        case .hard: baseScore = 500
        case .expert: baseScore = 3000
        }

        let bonus: Int
        if comboCount >= 2 {
            let maxBonus: Double
            switch gameDifficulty {
            case .easy: maxBonus = 700.0
            case .hard: maxBonus = 1200.0
            case .expert: maxBonus = 3500.0
            }
            let k: Double = 0.5

            let midpoint: Double
            switch gameDifficulty {
            case .easy: midpoint = 8.0
            case .hard: midpoint = 6.0
            case .expert: midpoint = 4.0
            }
            let x = Double(comboCount)

            let sigmoidValue = 1.0 / (1.0 + exp(-k * (x - midpoint)))
            bonus = Int(maxBonus * sigmoidValue)
        } else {
            bonus = 0
        }

        let comboBonus = bonus

        lastComboBonus = comboBonus

        score += baseScore + comboBonus
        problemsSolved += 1

        didSolveLastProblem = true

        currentCircuit.clear()
        generateNewProblem()
        if let newProblem = currentProblem {
            currentVector = newProblem.startBlochVector
        }

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            self.didSolveLastProblem = false
        }
    }

    public func handleWrongAnswer() -> Bool {
        comboCount = 0
        lastComboBonus = 0

        return false
    }
}
