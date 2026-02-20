import SwiftUI
import simd

@Observable
@MainActor
final class GameViewModel {

    let gameEngine: GameEngine

    init(gameEngine: GameEngine = GameEngine()) {
        self.gameEngine = gameEngine
    }

    var tutorialVector: BlochVector?

    var remainingTime: Int { gameEngine.remainingTime }

    var score: Int { gameEngine.score }

    var problemsSolved: Int { gameEngine.problemsSolved }

    var comboCount: Int { gameEngine.comboCount }

    var lastComboBonus: Int { gameEngine.lastComboBonus }

    var currentVector: BlochVector {
        tutorialVector ?? gameEngine.currentVector
    }

    var targetVector: BlochVector { gameEngine.targetVector }

    var distance: Double { gameEngine.currentDistance }

    var circuit: [QuantumGate] { gameEngine.currentCircuit.gates }

    var gameState: GameState { gameEngine.state }

    var didSolve: Bool { gameEngine.didSolveLastProblem }

    var finalScore: ScoreEntry? { gameEngine.finalScoreEntry }

    var isTimeLow: Bool { remainingTime <= 10 }

    var circuitGates: [QuantumGate] {
        get { gameEngine.currentCircuit.gates }
        set {
            gameEngine.clearCircuit()
            for gate in newValue {
                gameEngine.addGate(gate)
            }
        }
    }

    var canAddGate: Bool { !gameEngine.currentCircuit.isFull }

    var maxGates: Int { gameEngine.currentCircuit.maxGates }

    func prepareGame(difficulty: GameDifficulty = .easy) {
        gameEngine.start(difficulty: difficulty, startTimer: false)
    }

    func startGameLoop() {
        gameEngine.startGameLoop()
    }

    func startGame(difficulty: GameDifficulty = .easy) {
        gameEngine.start(difficulty: difficulty, startTimer: true)
    }

    func addGate(_ gate: QuantumGate) {
        gameEngine.addGate(gate)
    }

    func removeGate(at index: Int) {
        gameEngine.removeGate(at: index)
    }

    func clearCircuit() {
        gameEngine.clearCircuit()
    }

    func runCircuit() -> (isCorrect: Bool, isGameOver: Bool) {
        let isCorrect = gameEngine.checkCurrentState()
        if isCorrect {
            gameEngine.handleCorrectAnswer()
            return (isCorrect: true, isGameOver: false)
        } else {
            let isGameOver = gameEngine.handleWrongAnswer()
            return (isCorrect: false, isGameOver: isGameOver)
        }
    }

    var currentTutorialStep: TutorialStep = .intro1 {
        didSet {
            setTutorialVector(currentTutorialStep.initialVector)
            tutorialGateEnabled = false
            showTutorialNextButton = false
            updateFurthestReachedTutorialIndex()
        }
    }
    var isTutorialActive: Bool = false
    var showTutorialNextButton: Bool = true
    var tutorialGateEnabled: Bool = false
    private var furthestReachedTutorialIndex: Int = 0

    var canGoToPreviousTutorialStep: Bool {
        tutorialStepIndex(currentTutorialStep) > 0
    }

    var canGoToNextReachedTutorialStep: Bool {
        tutorialStepIndex(currentTutorialStep) < furthestReachedTutorialIndex
    }

    func startTutorial() {
        isTutorialActive = true
        furthestReachedTutorialIndex = 0
        currentTutorialStep = .intro1
        setTutorialVector(.zero)
        showTutorialNextButton = false
        tutorialGateEnabled = false
    }

    func advanceTutorialStep() {
        let currentIndex = tutorialStepIndex(currentTutorialStep)
        let nextIndex = currentIndex + 1

        if nextIndex < TutorialStep.allCases.count {
            withAnimation {
                currentTutorialStep = TutorialStep.allCases[nextIndex]
            }
        } else {
            endTutorial()
        }
    }

    func goToPreviousTutorialStep() {
        let currentIndex = tutorialStepIndex(currentTutorialStep)
        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else { return }

        withAnimation {
            currentTutorialStep = TutorialStep.allCases[previousIndex]
        }
    }

    func goToNextReachedTutorialStep() {
        let currentIndex = tutorialStepIndex(currentTutorialStep)
        let nextIndex = currentIndex + 1

        guard nextIndex <= furthestReachedTutorialIndex,
              nextIndex < TutorialStep.allCases.count else { return }

        withAnimation {
            currentTutorialStep = TutorialStep.allCases[nextIndex]
        }
    }

    func endTutorial() {
        withAnimation {
            isTutorialActive = false
            clearTutorialVector()
        }
    }

    func handleTutorialGateTap(_ gate: QuantumGate) {
        guard tutorialGateEnabled else { return }
        guard currentTutorialStep.targetGate == gate else { return }

        tutorialGateEnabled = false
        showTutorialNextButton = false

        Task {
            let startVector = currentVector.vector
            let (axis, angle) = rotationParameters(for: gate)

            let shouldAnimateTrajectory: Bool
            switch gate {
            case .s, .t: shouldAnimateTrajectory = true
            default: shouldAnimateTrajectory = false
            }

            if shouldAnimateTrajectory {
                let duration: Double = 1.0
                let fps: Double = 60
                let totalFrames = Int(duration * fps)

                for frame in 0...totalFrames {
                    let progress = Double(frame) / Double(totalFrames)
                    let t = 1.0 - pow(1.0 - progress, 3.0)
                    let currentAngle = angle * t

                    let rotated = rotate(vector: startVector, axis: axis, angle: currentAngle)

                    await MainActor.run {
                        self.setTutorialVector(BlochVector(rotated))
                    }

                    try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / fps))
                }
            } else {
                try? await Task.sleep(for: .milliseconds(200))

                let finalVector = rotate(vector: startVector, axis: axis, angle: angle)
                 await MainActor.run {
                     withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                         self.setTutorialVector(BlochVector(finalVector))
                     }
                 }
            }

            await MainActor.run {
                self.showTutorialNextButton = true
            }
        }
    }

    func setTutorialVector(_ vector: BlochVector) {
        self.tutorialVector = vector
    }

    func clearTutorialVector() {
        self.tutorialVector = nil
    }

    private func rotationParameters(for gate: QuantumGate) -> (axis: simd_double3, angle: Double) {
        switch gate {
        case .x: return (simd_double3(1, 0, 0), .pi)
        case .y: return (simd_double3(0, 1, 0), .pi)
        case .z: return (simd_double3(0, 0, 1), .pi)
        case .h:
            let axis = simd_normalize(simd_double3(1, 0, 1))
            return (axis, .pi)
        case .s: return (simd_double3(0, 0, 1), .pi / 2)
        case .t: return (simd_double3(0, 0, 1), .pi / 4)
        }
    }

    private func rotate(vector: simd_double3, axis: simd_double3, angle: Double) -> simd_double3 {
        let rotationWrapper = simd_quatd(angle: angle, axis: axis)
        return rotationWrapper.act(vector)
    }

    private func tutorialStepIndex(_ step: TutorialStep) -> Int {
        TutorialStep.allCases.firstIndex(of: step) ?? 0
    }

    private func updateFurthestReachedTutorialIndex() {
        let currentIndex = tutorialStepIndex(currentTutorialStep)
        if currentIndex > furthestReachedTutorialIndex {
            furthestReachedTutorialIndex = currentIndex
        }
    }
}
