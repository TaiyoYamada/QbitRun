import SwiftUI
import simd

@Observable
@MainActor
final class GameViewModel {

    private struct VectorAnimationStep {
        let path: VectorAnimationPath
        let duration: Double
    }

    private enum VectorAnimationPath {
        case axisRotation(start: simd_double3, axis: simd_double3, angle: Double)
        case slerp(from: simd_double3, to: simd_double3)
    }

    private enum VectorAnimationConfig {
        static let fps: Double = 60
        static let addOrRemoveDuration: Double = 0.16
        static let clearDuration: Double = 0.22
        static let minimumDuration: Double = 0.016
    }

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
            resetGameplayVectorAnimation()
            gameEngine.clearCircuit()
            for gate in newValue {
                gameEngine.addGate(gate)
            }
        }
    }

    var canAddGate: Bool { !gameEngine.currentCircuit.isFull }

    var maxGates: Int { gameEngine.currentCircuit.maxGates }

    @ObservationIgnored
    private var gameplayVectorAnimationQueue: [VectorAnimationStep] = []

    @ObservationIgnored
    private var gameplayVectorAnimationTask: Task<Void, Never>?

    func prepareGame(difficulty: GameDifficulty = .easy) {
        resetGameplayVectorAnimation()
        gameEngine.start(difficulty: difficulty, startTimer: false)
    }

    func startGameLoop() {
        gameEngine.startGameLoop()
    }

    func startGame(difficulty: GameDifficulty = .easy) {
        resetGameplayVectorAnimation()
        gameEngine.start(difficulty: difficulty, startTimer: true)
    }

    func addGate(_ gate: QuantumGate) {
        guard canAddGate else { return }
        let fromVector = gameEngine.currentVector
        let (axis, angle) = gate.blochRotation

        gameEngine.addGate(gate)
        enqueueGameplayVectorAnimation(
            path: .axisRotation(start: fromVector.vector, axis: axis, angle: angle),
            baseDuration: VectorAnimationConfig.addOrRemoveDuration
        )
    }

    func removeGate(at index: Int) {
        guard circuitGates.indices.contains(index) else { return }
        let fromVector = gameEngine.currentVector
        let gate = circuitGates[index]
        let (axis, angle) = gate.blochRotation

        gameEngine.removeGate(at: index)
        enqueueGameplayVectorAnimation(
            path: .axisRotation(start: fromVector.vector, axis: axis, angle: -angle),
            baseDuration: VectorAnimationConfig.addOrRemoveDuration
        )
    }

    func clearCircuit() {
        let fromVector = gameEngine.currentVector
        gameEngine.clearCircuit()
        let toVector = gameEngine.currentVector
        enqueueGameplayVectorAnimation(
            path: .slerp(from: fromVector.vector, to: toVector.vector),
            baseDuration: VectorAnimationConfig.clearDuration
        )
    }

    func runCircuit() -> (isCorrect: Bool, isGameOver: Bool) {
        let isCorrect = gameEngine.checkCurrentState()
        if isCorrect {
            gameEngine.handleCorrectAnswer()
            resetGameplayVectorAnimation()
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
        resetGameplayVectorAnimation()
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
            currentTutorialStep = TutorialStep.allCases[nextIndex]
        } else {
            endTutorial()
        }
    }

    func goToPreviousTutorialStep() {
        let currentIndex = tutorialStepIndex(currentTutorialStep)
        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else { return }

        currentTutorialStep = TutorialStep.allCases[previousIndex]
    }

    func goToNextReachedTutorialStep() {
        let currentIndex = tutorialStepIndex(currentTutorialStep)
        let nextIndex = currentIndex + 1

        guard nextIndex <= furthestReachedTutorialIndex,
              nextIndex < TutorialStep.allCases.count else { return }

        currentTutorialStep = TutorialStep.allCases[nextIndex]
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
            let (axis, totalAngle) = gate.blochRotation

            let duration: Double = 0.6
            let fps: Double = 60
            let totalFrames = Int(duration * fps)

            for frame in 0...totalFrames {
                let progress = Double(frame) / Double(totalFrames)
                let t = 1.0 - pow(1.0 - progress, 3.0)
                let currentAngle = totalAngle * t

                let rotated = rotate(vector: startVector, axis: axis, angle: currentAngle)

                await MainActor.run {
                    self.setTutorialVector(BlochVector(rotated))
                }

                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / fps))
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

    private func enqueueGameplayVectorAnimation(path: VectorAnimationPath, baseDuration: Double) {
        guard !isTutorialActive else { return }
        if case let .slerp(from, to) = path {
            guard simd_distance(from, to) > 0.000_1 else { return }
        }

        let duration = adjustedDuration(for: baseDuration)
        let step = VectorAnimationStep(path: path, duration: duration)
        gameplayVectorAnimationQueue.append(step)
        startGameplayVectorAnimationIfNeeded()
    }

    private func startGameplayVectorAnimationIfNeeded() {
        guard gameplayVectorAnimationTask == nil else { return }

        gameplayVectorAnimationTask = Task { @MainActor in
            await self.processGameplayVectorAnimationQueue()
        }
    }

    private func processGameplayVectorAnimationQueue() async {
        defer {
            gameplayVectorAnimationTask = nil
            if !isTutorialActive {
                tutorialVector = nil
            }
        }

        while !gameplayVectorAnimationQueue.isEmpty {
            if Task.isCancelled { break }
            let step = gameplayVectorAnimationQueue.removeFirst()
            await animateGameplayVectorStep(step)
        }
    }

    private func animateGameplayVectorStep(_ step: VectorAnimationStep) async {
        let totalFrames = max(1, Int(step.duration * VectorAnimationConfig.fps))
        let frameDurationNs = UInt64(1_000_000_000 / VectorAnimationConfig.fps)

        for frame in 0...totalFrames {
            if Task.isCancelled { return }

            let progress = Double(frame) / Double(totalFrames)
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            let interpolated: simd_double3
            switch step.path {
            case let .axisRotation(start, axis, angle):
                let currentAngle = angle * easedProgress
                interpolated = rotate(vector: start, axis: axis, angle: currentAngle)
            case let .slerp(from, to):
                interpolated = slerp(from: from, to: to, t: easedProgress)
            }
            tutorialVector = BlochVector(interpolated)

            if frame < totalFrames {
                do {
                    try await Task.sleep(nanoseconds: frameDurationNs)
                } catch {
                    return
                }
            }
        }
    }

    private func resetGameplayVectorAnimation() {
        gameplayVectorAnimationTask?.cancel()
        gameplayVectorAnimationTask = nil
        gameplayVectorAnimationQueue.removeAll(keepingCapacity: false)
        tutorialVector = nil
    }

    private func adjustedDuration(for baseDuration: Double) -> Double {
        let backlog = gameplayVectorAnimationQueue.count + (gameplayVectorAnimationTask == nil ? 0 : 1)
        let factor: Double
        switch backlog {
        case 0...1:
            factor = 1.0
        case 2:
            factor = 0.45
        case 3:
            factor = 0.33
        case 4:
            factor = 0.25
        case 5:
            factor = 0.18
        default:
            factor = 0.12
        }

        return max(VectorAnimationConfig.minimumDuration, baseDuration * factor)
    }

    private func slerp(from source: simd_double3, to destination: simd_double3, t: Double) -> simd_double3 {
        let clampedT = max(0.0, min(1.0, t))
        let from = simd_normalize(source)
        let to = simd_normalize(destination)
        let dot = max(-1.0, min(1.0, simd_dot(from, to)))

        if dot > 0.9995 {
            return simd_normalize(from * (1.0 - clampedT) + to * clampedT)
        }

        if dot < -0.9995 {
            var orthogonal = simd_cross(from, simd_double3(1, 0, 0))
            if simd_length_squared(orthogonal) < 0.000001 {
                orthogonal = simd_cross(from, simd_double3(0, 1, 0))
            }
            orthogonal = simd_normalize(orthogonal)
            let rotation = simd_quatd(angle: .pi * clampedT, axis: orthogonal)
            return simd_normalize(rotation.act(from))
        }

        let angle = acos(dot)
        let sinAngle = sin(angle)
        let fromWeight = sin((1.0 - clampedT) * angle) / sinAngle
        let toWeight = sin(clampedT * angle) / sinAngle
        return simd_normalize(from * fromWeight + to * toWeight)
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
