import SwiftUI
import UIKit
import simd

@Observable
@MainActor
final class GameViewModel {

    let gameEngine: GameEngine
    let vectorAnimator = VectorAnimator()
    let tutorialManager = TutorialManager()

    @ObservationIgnored
    let heavyFeedback: UIImpactFeedbackGenerator = {
        let gen = UIImpactFeedbackGenerator(style: .heavy)
        gen.prepare()
        return gen
    }()

    @ObservationIgnored
    let mediumFeedback: UIImpactFeedbackGenerator = {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.prepare()
        return gen
    }()

    @ObservationIgnored
    let lightFeedback: UIImpactFeedbackGenerator = {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.prepare()
        return gen
    }()

    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
    }

    convenience init() {
        self.init(gameEngine: GameEngine())
    }


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


    var showCountdown: Bool = true
    var countdownValue: Int = 3
    var countdownPhase: CountdownOverlayView.Phase = .countdown
    var countdownScale: CGFloat = 0.5
    var countdownOpacity: Double = 0.0

    var showSuccessEffect = false
    var showFailureEffect = false
    var showComboEffect = false
    var highlightedGate: QuantumGate?
    var showExitConfirmation = false

    var showPostTutorialGuide = false
    var postTutorialGuideStep: PostTutorialGuideStep = .matchTargetVector
    var shouldMarkTutorialCompletionOnGameStart = false
    var isTransitioningToResult = false

    @ObservationIgnored
    var comboAnimationTask: Task<Void, Never>?

    @ObservationIgnored
    var gameEndTask: Task<Void, Never>?

    var isGameModalPresented: Bool {
        showExitConfirmation || showPostTutorialGuide || isTransitioningToResult
    }

    var isInteractionLocked: Bool {
        showCountdown || showExitConfirmation || showPostTutorialGuide || isTransitioningToResult
    }


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

    func runCircuit(audioManager: AudioManager) {
        guard !circuitGates.isEmpty else { return }

        let isCorrect = gameEngine.checkCurrentState()

        if isCorrect {
            gameEngine.handleCorrectAnswer()
            vectorAnimator.reset()
            audioManager.playSFX(.success)
            showSuccessEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showSuccessEffect = false
                withAnimation(.easeOut(duration: 0.2)) {
                    clearCircuit()
                }
            }
        } else {
            _ = gameEngine.handleWrongAnswer()
            audioManager.playSFX(.miss)
            showFailureEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showFailureEffect = false
            }
        }
    }


    func startCountdown() {
        showCountdown = true
        countdownValue = 3
        countdownPhase = .countdown

        Task { @MainActor in
            for i in (1...3).reversed() {
                countdownValue = i
                countdownPhase = .countdown
                announceForVoiceOver("\(i)")
                await animateCountdownStep()
            }

            countdownValue = 0
            countdownPhase = .start
            announceForVoiceOver("Start.")
            await animateStartStep()

            withAnimation(.easeOut(duration: 0.5)) {
                showCountdown = false
            }

            startGameLoop()
        }
    }

    func startTimeUpTransition(with score: ScoreEntry, onGameEnd: @escaping (ScoreEntry) -> Void) {
        guard !isTransitioningToResult else { return }

        isTransitioningToResult = true
        gameEndTask?.cancel()
        gameEndTask = Task { @MainActor in
            showCountdown = true
            countdownPhase = .timeUp
            await animateTimeUpStep()

            if Task.isCancelled { return }
            onGameEnd(score)
        }
    }

    @MainActor
    private func animateCountdownStep() async {
        countdownScale = 0.5
        countdownOpacity = 0.0

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            countdownScale = 1.2
            countdownOpacity = 1.0
        }

        heavyFeedback.impactOccurred()

        try? await Task.sleep(for: .milliseconds(600))

        withAnimation(.easeIn(duration: 0.2)) {
            countdownScale = 1.5
            countdownOpacity = 0.0
        }

        try? await Task.sleep(for: .milliseconds(200))
    }

    @MainActor
    private func animateStartStep() async {
        countdownScale = 0.5
        countdownOpacity = 0.0

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            countdownScale = 1.5
            countdownOpacity = 1.0
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        try? await Task.sleep(for: .milliseconds(800))

        withAnimation(.easeOut(duration: 0.3)) {
            countdownScale = 2.0
            countdownOpacity = 0.0
        }
    }

    @MainActor
    private func animateTimeUpStep() async {
        countdownScale = 0.5
        countdownOpacity = 0.0
        announceForVoiceOver("Time up.")

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            countdownScale = 1.5
            countdownOpacity = 1.0
        }

        UINotificationFeedbackGenerator().notificationOccurred(.warning)

        try? await Task.sleep(for: .milliseconds(1900))
    }


    func beginPostTutorialGuide() {
        shouldMarkTutorialCompletionOnGameStart = true
        postTutorialGuideStep = .matchTargetVector

        withAnimation(.easeOut(duration: 0.2)) {
            showPostTutorialGuide = true
        }
    }

    func advancePostTutorialGuide(audioManager: AudioManager) {
        audioManager.playSFX(.button)
        lightFeedback.impactOccurred()

        if let next = PostTutorialGuideStep(rawValue: postTutorialGuideStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.25)) {
                postTutorialGuideStep = next
            }
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            showPostTutorialGuide = false
        }

        Task {
            try? await Task.sleep(for: .milliseconds(250))
            startCountdown()
        }
    }


    func triggerComboAnimation() {
        comboAnimationTask?.cancel()

        comboAnimationTask = Task { @MainActor in
            withAnimation(.none) {
                showComboEffect = false
            }

            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showComboEffect = true
            }

            try? await Task.sleep(for: .milliseconds(700))
            if Task.isCancelled { return }

            withAnimation(.easeOut(duration: 0.3)) {
                showComboEffect = false
            }
        }
    }


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


    func announceForVoiceOver(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }


    func cleanup() {
        comboAnimationTask?.cancel()
        gameEndTask?.cancel()
    }
}
