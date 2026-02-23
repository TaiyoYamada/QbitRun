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
        guard canAddGate else { return }

        let startVector = currentVector.vector
        let (axis, totalAngle) = gate.blochRotation

        gameEngine.addGate(gate)

        Task {
            let duration: Double = 0.4
            let fps: Double = 60
            let totalFrames = Int(duration * fps)
            
            for frame in 0...totalFrames {
                let progress = Double(frame) / Double(totalFrames)
                let t = 1.0 - pow(1.0 - progress, 3.0)
                let currentAngle = totalAngle * t
                
                let rotated = rotate(vector: startVector, axis: axis, angle: currentAngle)
                
                await MainActor.run {
                    self.tutorialVector = BlochVector(rotated)
                }
                
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / fps))
            }

            await MainActor.run {
                self.tutorialVector = nil
            }
        }
    }

    func removeGate(at index: Int) {
        let gate = circuitGates[index]
        let startVector = currentVector.vector

        var (axis, totalAngle) = gate.blochRotation
        if gate == .s || gate == .t {
            totalAngle = -totalAngle
        } else {
            totalAngle = -totalAngle
        }
        
        gameEngine.removeGate(at: index)
        
        Task {
            let duration: Double = 0.4
            let fps: Double = 60
            let totalFrames = Int(duration * fps)
            
            for frame in 0...totalFrames {
                let progress = Double(frame) / Double(totalFrames)
                let t = 1.0 - pow(1.0 - progress, 3.0)
                let currentAngle = totalAngle * t
                
                let rotated = rotate(vector: startVector, axis: axis, angle: currentAngle)
                
                await MainActor.run {
                    self.tutorialVector = BlochVector(rotated)
                }
                
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / fps))
            }
            
            await MainActor.run {
                self.tutorialVector = nil
            }
        }
    }

    func clearCircuit() {
        let startVector = currentVector.vector
        let targetBlochVector = gameEngine.currentProblem?.startBlochVector ?? .zero
        let targetVector = targetBlochVector.vector
        
        gameEngine.clearCircuit()

        let dot = simd_dot(simd_normalize(startVector), simd_normalize(targetVector))

        if dot > 0.999 { return }
        
        var axis = simd_cross(simd_normalize(startVector), simd_normalize(targetVector))
        let axisLength = simd_length(axis)

        if axisLength < 0.001 && dot < -0.999 {
            let arbitraryUp = abs(startVector.x) < 0.9 ? simd_double3(1, 0, 0) : simd_double3(0, 1, 0)
            axis = simd_normalize(simd_cross(startVector, arbitraryUp))
        } else {
            axis = simd_normalize(axis)
        }
        
        let totalAngle = acos(max(-1.0, min(1.0, dot)))
        
        Task {
            let duration: Double = 0.5
            let fps: Double = 60
            let totalFrames = Int(duration * fps)
            
            for frame in 0...totalFrames {
                let progress = Double(frame) / Double(totalFrames)
                let t = 1.0 - pow(1.0 - progress, 3.0)
                let currentAngle = totalAngle * t

                let rotationWrapper = simd_quatd(angle: currentAngle, axis: axis)
                let rotated = rotationWrapper.act(startVector)
                
                await MainActor.run {
                    self.tutorialVector = BlochVector(rotated)
                }
                
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / fps))
            }
            
            await MainActor.run {
                self.tutorialVector = nil
            }
        }
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
                let progress = Double(frame) / Double(totalFrames)z
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
