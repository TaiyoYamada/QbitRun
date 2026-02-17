import SwiftUI
import simd

/// ゲーム画面のViewModel
@Observable
@MainActor
final class GameViewModel {
    
    // MARK: - Application層への参照
    
    /// ゲームエンジン（ビジネスロジック）
    let gameEngine: GameEngine
    
    // MARK: - 初期化
    
    init(gameEngine: GameEngine = GameEngine()) {
        self.gameEngine = gameEngine
    }
    
    // MARK: - Tutorial State
    var tutorialVector: BlochVector?
    
    // MARK: - 表示用プロパティ（GameEngineからの橋渡し）
    
    /// 残り時間（秒）
    var remainingTime: Int { gameEngine.remainingTime }
    
    /// スコア
    var score: Int { gameEngine.score }
    
    /// 解いた問題数
    var problemsSolved: Int { gameEngine.problemsSolved }
    
    /// 現在のコンボ数
    var comboCount: Int { gameEngine.comboCount }
    
    /// 直前のコンボボーナス
    var lastComboBonus: Int { gameEngine.lastComboBonus }
    
    /// 現在のブロッホベクトル
    var currentVector: BlochVector {
        tutorialVector ?? gameEngine.currentVector
    }
    
    /// ターゲットのブロッホベクトル
    var targetVector: BlochVector { gameEngine.targetVector }
    
    /// 現在とターゲットの距離
    var distance: Double { gameEngine.currentDistance }
    
    /// 現在の回路（ゲート列）
    var circuit: [QuantumGate] { gameEngine.currentCircuit.gates }
    
    /// ゲーム状態
    var gameState: GameState { gameEngine.state }
    
    /// 正解したかどうか（アニメーション用）
    var didSolve: Bool { gameEngine.didSolveLastProblem }
    
    /// ゲーム終了時のスコア
    var finalScore: ScoreEntry? { gameEngine.finalScoreEntry }
    
    /// タイマーが残り10秒以下か
    var isTimeLow: Bool { remainingTime <= 10 }
    
    /// 回路のゲート配列（Single Source of Truth）
    var circuitGates: [QuantumGate] {
        get { gameEngine.currentCircuit.gates }
        set {
            gameEngine.clearCircuit()
            for gate in newValue {
                gameEngine.addGate(gate)
            }
        }
    }
    
    /// ゲートを追加可能か
    var canAddGate: Bool { gameEngine.currentCircuit.gateCount < 5 }
    
    // MARK: - ユーザー操作
    
    /// ゲームを開始（カウントダウン前準備）
    /// - Parameter difficulty: ゲームの難易度
    func prepareGame(difficulty: GameDifficulty = .easy) {
        gameEngine.start(difficulty: difficulty, startTimer: false)
    }
    
    /// ゲームの計測を開始（カウントダウン終了後）
    func startGameLoop() {
        gameEngine.startGameLoop()
    }
    
    /// ゲームを開始（即時）
    /// - Parameter difficulty: ゲームの難易度
    func startGame(difficulty: GameDifficulty = .easy) {
        gameEngine.start(difficulty: difficulty, startTimer: true)
    }
    
    /// ゲートを追加
    func addGate(_ gate: QuantumGate) {
        gameEngine.addGate(gate)
    }
    
    /// ゲートを削除
    func removeGate(at index: Int) {
        gameEngine.removeGate(at: index)
    }
    
    /// 回路をクリア
    func clearCircuit() {
        gameEngine.clearCircuit()
    }
    
    /// 回路を実行して判定
    /// - Returns: (isCorrect: 正解か, isGameOver: ゲームオーバーか)
    func runCircuit() -> (isCorrect: Bool, isGameOver: Bool) {
        // 現在の状態がターゲットに十分近いか判定
        let isCorrect = gameEngine.checkCurrentState()
        if isCorrect {
            gameEngine.handleCorrectAnswer()
            return (isCorrect: true, isGameOver: false)
        } else {
            let isGameOver = gameEngine.handleWrongAnswer()
            return (isCorrect: false, isGameOver: isGameOver)
        }
    }

    // MARK: - Tutorial Support
    
    var currentTutorialStep: TutorialStep = .intro {
        didSet {
            // Update vector when step changes
            setTutorialVector(currentTutorialStep.initialVector)
        }
    }
    var isTutorialActive: Bool = false
    var showTutorialNextButton: Bool = true
    
    func startTutorial() {
        isTutorialActive = true
        currentTutorialStep = .intro
        setTutorialVector(.zero)
        showTutorialNextButton = true
    }
    
    func advanceTutorialStep() {
        guard let currentIndex = TutorialStep.allCases.firstIndex(of: currentTutorialStep) else { return }
        let nextIndex = currentIndex + 1
        
        if nextIndex < TutorialStep.allCases.count {
            withAnimation {
                currentTutorialStep = TutorialStep.allCases[nextIndex]
                
                // Logic to show/hide Next button based on whether a gate tap is required
                if currentTutorialStep.targetGate != nil {
                     showTutorialNextButton = false
                } else {
                     showTutorialNextButton = true
                }
            }
        } else {
            endTutorial()
        }
    }
    
    func endTutorial() {
        withAnimation {
            isTutorialActive = false
            clearTutorialVector()
        }
    }
    
    func handleTutorialGateTap(_ gate: QuantumGate) {
        // Only allow target gate
        guard currentTutorialStep.targetGate == gate else { return }
        
        // Hide next button during animation
        showTutorialNextButton = false
        
        // Animate
        Task {
            let startVector = currentVector.vector
            let (axis, angle) = rotationParameters(for: gate)
            
            // Check if we should animate trajectory (Only for rotation gates like S, T)
            let shouldAnimateTrajectory: Bool
            switch gate {
            case .s, .t: shouldAnimateTrajectory = true
            default: shouldAnimateTrajectory = false // X, Y, Z, H are instantaneous jumps
            }
            
            if shouldAnimateTrajectory {
                let duration: Double = 1.0
                let fps: Double = 60
                let totalFrames = Int(duration * fps)
                
                for frame in 0...totalFrames {
                    let progress = Double(frame) / Double(totalFrames)
                    let t = 1.0 - pow(1.0 - progress, 3.0) // Ease out
                    let currentAngle = angle * t
                    
                    let rotated = rotate(vector: startVector, axis: axis, angle: currentAngle)
                    
                    await MainActor.run {
                        self.setTutorialVector(BlochVector(rotated))
                    }
                    
                    try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / fps))
                }
            } else {
                // Instantaneous update for X, Y, Z, H
                // Add a small delay to let the user see the button press visual
                try? await Task.sleep(for: .milliseconds(200))
                
                let finalVector = rotate(vector: startVector, axis: axis, angle: angle)
                 await MainActor.run {
                     // Use withAnimation to smooth the jump slightly if desired, or standard set for instant
                     withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                         self.setTutorialVector(BlochVector(finalVector))
                     }
                 }
            }
            
            // Animation done, show next button
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
    
    // Helper methods for animation (copied from TutorialViewModel)
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
}
