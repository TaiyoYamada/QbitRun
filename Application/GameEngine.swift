import Foundation

/// ゲームの進行状態を表す列挙型
public enum GameState: Sendable {
    case ready
    case playing
    case paused
    case finished
}

/// 問題生成・回路操作・正誤判定・スコア管理・タイマーを統括
@Observable
@MainActor
public final class GameEngine {


    private let timerService: GameTimerService
    private let scoreManager = GameScoreManager()
    private let problemManager = ProblemManager()
    private let judgeService = JudgeService()


    public private(set) var state: GameState = .ready

    public var remainingTime: Int { timerService.remainingTime }

    public var score: Int { scoreManager.score }

    public var problemsSolved: Int { scoreManager.problemsSolved }

    public var comboCount: Int { scoreManager.comboCount }

    public var lastComboBonus: Int { scoreManager.lastComboBonus }

    public var missCount: Int { scoreManager.missCount }

    public var currentProblem: Problem? { problemManager.currentProblem }

    public private(set) var currentCircuit = Circuit(maxGates: 4)

    public private(set) var currentVector: BlochVector = .zero

    public private(set) var didSolveLastProblem: Bool = false

    public private(set) var finalScoreEntry: ScoreEntry?

    private var gameDifficulty: GameDifficulty = .easy

    private var maxGatesForDifficulty: Int {
        switch gameDifficulty {
        case .easy, .hard: return 4
        case .expert: return 6
        }
    }

    public var targetVector: BlochVector {
        guard let problem = currentProblem else { return .zero }
        return BlochVector(from: problem.targetState)
    }

    public var currentDistance: Double {
        guard let problem = currentProblem else { return 1.0 }
        let currentState = currentCircuit.apply(to: problem.startState)
        return currentState.fidelity(with: problem.targetState)
    }


    public init(gameDuration: Int = 60) {
        self.timerService = GameTimerService(duration: gameDuration)
        self.timerService.onTimeUp = { [weak self] in
            self?.endGame()
        }
    }


    public func start(difficulty: GameDifficulty = .easy, startTimer: Bool = true) {
        guard state == .ready else { return }

        self.gameDifficulty = difficulty
        state = .playing

        scoreManager.reset()
        currentCircuit = Circuit(maxGates: maxGatesForDifficulty)
        didSolveLastProblem = false
        finalScoreEntry = nil

        problemManager.reset()
        problemManager.generateNewProblem(
            difficulty: gameDifficulty,
            problemNumber: scoreManager.problemsSolved
        )

        if let problem = currentProblem {
            currentVector = problem.startBlochVector
        } else {
            currentVector = .zero
        }

        if startTimer {
            timerService.start()
        } else {
            timerService.reset()
        }
    }

    public func startGameLoop() {
        guard state == .playing else { return }
        timerService.resume()
    }

    public func pause() {
        guard state == .playing else { return }
        state = .paused
        timerService.pause()
    }

    public func resume() {
        guard state == .paused else { return }
        state = .playing
        timerService.resume()
    }

    public func reset() {
        timerService.reset()
        state = .ready
        scoreManager.reset()
        currentCircuit = Circuit(maxGates: maxGatesForDifficulty)
        problemManager.reset()
        currentVector = .zero
        didSolveLastProblem = false
        finalScoreEntry = nil
    }

    private func endGame() {
        state = .finished
        timerService.pause()

        finalScoreEntry = ScoreEntry(
            score: scoreManager.score,
            problemsSolved: scoreManager.problemsSolved,
            difficulty: gameDifficulty
        )
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

        scoreManager.recordCorrectAnswer(difficulty: gameDifficulty)
        didSolveLastProblem = true

        currentCircuit.clear()
        problemManager.generateNewProblem(
            difficulty: gameDifficulty,
            problemNumber: scoreManager.problemsSolved
        )
        if let newProblem = currentProblem {
            currentVector = newProblem.startBlochVector
        }

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            self.didSolveLastProblem = false
        }
    }

    public func handleWrongAnswer() -> Bool {
        scoreManager.recordWrongAnswer()
        return false
    }
}
