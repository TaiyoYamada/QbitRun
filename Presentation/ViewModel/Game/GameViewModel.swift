import SwiftUI
import simd

@Observable
@MainActor
final class GameViewModel {

    let gameEngine: GameEngine
    let vectorAnimator = VectorAnimator()
    let tutorialManager = TutorialManager()

    init(gameEngine: GameEngine = GameEngine()) {
        self.gameEngine = gameEngine
    }

    // MARK: - Game engine forwarding

    var remainingTime: Int { gameEngine.remainingTime }

    var score: Int { gameEngine.score }

    var problemsSolved: Int { gameEngine.problemsSolved }

    var comboCount: Int { gameEngine.comboCount }

    var lastComboBonus: Int { gameEngine.lastComboBonus }

    var currentVector: BlochVector {
        tutorialManager.tutorialVector ?? vectorAnimator.animatedVector ?? gameEngine.currentVector
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
            vectorAnimator.reset()
            gameEngine.clearCircuit()
            for gate in newValue {
                gameEngine.addGate(gate)
            }
        }
    }

    var canAddGate: Bool { !gameEngine.currentCircuit.isFull }

    var maxGates: Int { gameEngine.currentCircuit.maxGates }

    // MARK: - Tutorial forwarding

    var currentTutorialStep: TutorialStep {
        tutorialManager.currentStep
    }

    var isTutorialActive: Bool {
        tutorialManager.isActive
    }

    var showTutorialNextButton: Bool {
        get { tutorialManager.showNextButton }
        set { if newValue { tutorialManager.enableNextButton() } }
    }

    var tutorialGateEnabled: Bool {
        get { tutorialManager.gateEnabled }
        set { if newValue { tutorialManager.enableGate() } }
    }

    var canGoToPreviousTutorialStep: Bool {
        tutorialManager.canGoToPreviousStep
    }

    var canGoToNextReachedTutorialStep: Bool {
        tutorialManager.canGoToNextReachedStep
    }

    // MARK: - Game flow

    func prepareGame(difficulty: GameDifficulty = .easy) {
        vectorAnimator.reset()
        gameEngine.start(difficulty: difficulty, startTimer: false)
    }

    func startGameLoop() {
        gameEngine.startGameLoop()
    }

    func startGame(difficulty: GameDifficulty = .easy) {
        vectorAnimator.reset()
        gameEngine.start(difficulty: difficulty, startTimer: true)
    }

    func addGate(_ gate: QuantumGate) {
        guard canAddGate else { return }
        let fromVector = gameEngine.currentVector
        let (axis, angle) = gate.blochRotation

        gameEngine.addGate(gate)

        guard !tutorialManager.isActive else { return }
        vectorAnimator.enqueue(
            path: .axisRotation(start: fromVector.vector, axis: axis, angle: angle),
            baseDuration: VectorAnimator.Config.addOrRemoveDuration
        )
    }

    func removeGate(at index: Int) {
        guard circuitGates.indices.contains(index) else { return }
        let fromVector = gameEngine.currentVector
        let gate = circuitGates[index]
        let (axis, angle) = gate.blochRotation

        gameEngine.removeGate(at: index)

        guard !tutorialManager.isActive else { return }
        vectorAnimator.enqueue(
            path: .axisRotation(start: fromVector.vector, axis: axis, angle: -angle),
            baseDuration: VectorAnimator.Config.addOrRemoveDuration
        )
    }

    func clearCircuit() {
        let fromVector = gameEngine.currentVector
        gameEngine.clearCircuit()
        let toVector = gameEngine.currentVector

        guard !tutorialManager.isActive else { return }
        vectorAnimator.enqueue(
            path: .slerp(from: fromVector.vector, to: toVector.vector),
            baseDuration: VectorAnimator.Config.clearDuration
        )
    }

    func runCircuit() -> (isCorrect: Bool, isGameOver: Bool) {
        let isCorrect = gameEngine.checkCurrentState()
        if isCorrect {
            gameEngine.handleCorrectAnswer()
            vectorAnimator.reset()
            return (isCorrect: true, isGameOver: false)
        } else {
            let isGameOver = gameEngine.handleWrongAnswer()
            return (isCorrect: false, isGameOver: isGameOver)
        }
    }

    // MARK: - Tutorial delegation

    func startTutorial() {
        vectorAnimator.reset()
        tutorialManager.start()
    }

    func advanceTutorialStep() {
        tutorialManager.advanceStep()
    }

    func goToPreviousTutorialStep() {
        tutorialManager.goToPreviousStep()
    }

    func goToNextReachedTutorialStep() {
        tutorialManager.goToNextReachedStep()
    }

    func endTutorial() {
        tutorialManager.end()
    }

    func handleTutorialGateTap(_ gate: QuantumGate) {
        tutorialManager.handleGateTap(gate, vectorAnimator: vectorAnimator)
    }

    func setTutorialVector(_ vector: BlochVector) {
        tutorialManager.setVector(vector)
    }

    func clearTutorialVector() {
        tutorialManager.clearVector()
    }
}
