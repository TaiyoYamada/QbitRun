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
    /// ゲーム時間（60秒）
    private let gameDuration: TimeInterval = 60
    
    /// 1問あたりの基本スコア
    private let baseScorePerProblem = 100
    
    /// お手つきの上限
    private let maxMisses = 3

    // MARK: - 公開プロパティ

    /// 現在のゲーム状態
    public private(set) var state: GameState = .ready
    
    /// 残り時間（秒）
    public private(set) var remainingTime: Int = 60
    
    /// 現在のスコア
    public private(set) var score: Int = 0
    
    /// 解いた問題数
    public private(set) var problemsSolved: Int = 0
    
    /// 現在のコンボ数
    public private(set) var comboCount: Int = 0
    
    /// コンボによる直前の加点（UI表示用）
    public private(set) var lastComboBonus: Int = 0
    
    /// お手つき回数
    public private(set) var missCount: Int = 0
    
    /// 現在の問題
    public private(set) var currentProblem: Problem?
    
    /// 現在の回路
    public private(set) var currentCircuit = Circuit()
    
    /// 現在のブロッホベクトル
    public private(set) var currentVector: BlochVector = .zero
    
    /// ターゲットのブロッホベクトル
    public var targetVector: BlochVector {
        guard let problem = currentProblem else { return .zero }
        return BlochVector(from: problem.targetState)
    }
    
    /// 現在とターゲットの距離（0.0〜1.0）
    public var currentDistance: Double {
        guard let problem = currentProblem else { return 1.0 }
        let currentState = currentCircuit.apply(to: problem.startState)
        let targetState = problem.targetState
        return currentState.fidelity(with: targetState)
    }
    
    /// 最後に正解したかどうか（アニメーション用）
    public private(set) var didSolveLastProblem: Bool = false
    
    /// ゲーム終了時のスコアエントリ
    public private(set) var finalScoreEntry: ScoreEntry?
    
    // MARK: - 内部プロパティ
    
    /// ゲームの難易度
    private var gameDifficulty: GameDifficulty = .easy
    
    /// 問題生成器
    private let problemGenerator = ProblemGenerator()
    
    /// 前回の問題キー（同じ問題の連続を防ぐ）
    private var lastProblemKey: String?
    
    /// 正解判定サービス
    private let judgeService = JudgeService()
    
    /// タイマー用のTask
    private var timerTask: Task<Void, Never>?
    
    // MARK: - ゲーム制御
    /// ゲームを開始
    public func start(difficulty: GameDifficulty = .easy, startTimer: Bool = true) {
        guard state == .ready else { return }
        
        // 難易度を設定
        self.gameDifficulty = difficulty
        
        // 状態をリセット
        state = .playing // プレイ中扱いにするが、タイマーは回さない
        remainingTime = Int(gameDuration)
        score = 0
        problemsSolved = 0
        comboCount = 0
        lastComboBonus = 0
        missCount = 0
        currentCircuit = Circuit()
        didSolveLastProblem = false
        finalScoreEntry = nil
        
        // 最初の問題を生成
        generateNewProblem()
        
        // 開始状態のベクトルを設定
        if let problem = currentProblem {
            currentVector = problem.startBlochVector
        } else {
            currentVector = .zero
        }
        
        // タイマーを開始（オプション）
        if startTimer {
            self.startTimer()
        }
    }
    
    /// タイマーループを開始（カウントダウン後に呼ぶ）
    public func startGameLoop() {
        guard state == .playing, timerTask == nil else { return }
        startTimer()
    }
    
    /// ゲームを一時停止
    public func pause() {
        guard state == .playing else { return }
        state = .paused
        timerTask?.cancel()
    }
    
    /// ゲームを再開
    public func resume() {
        guard state == .paused else { return }
        state = .playing
        startTimer()
    }
    
    /// ゲームをリセット（最初からやり直し）
    public func reset() {
        timerTask?.cancel()
        state = .ready
        remainingTime = Int(gameDuration)
        score = 0
        problemsSolved = 0
        comboCount = 0
        lastComboBonus = 0
        missCount = 0
        currentCircuit = Circuit()
        currentProblem = nil
        currentVector = .zero
        didSolveLastProblem = false
        finalScoreEntry = nil
    }
    
    /// ゲームを終了
    private func endGame() {
        state = .finished
        timerTask?.cancel()
        
        // スコアエントリを作成
        finalScoreEntry = ScoreEntry(
            score: score,
            problemsSolved: problemsSolved,
            difficulty: gameDifficulty
        )
    }
    
    // MARK: - タイマー

    /// タイマーを開始
    private func startTimer() {
        timerTask = Task { [weak self] in
            // 1秒ごとにループ
            while !Task.isCancelled {
                // 1秒待機
                try? await Task.sleep(for: .seconds(1))
                
                guard let self = self, self.state == .playing else { break }
                
                // 残り時間を減らす
                self.remainingTime -= 1
                
                // 時間切れチェック
                if self.remainingTime <= 0 {
                    self.endGame()
                    break
                }
            }
        }
    }
    
    // MARK: - 問題管理
    
    /// 新しい問題を生成
    private func generateNewProblem() {
        let result = problemGenerator.generateProblem(gameDifficulty: gameDifficulty, problemNumber: problemsSolved, lastProblemKey: lastProblemKey)
        currentProblem = result.problem
        lastProblemKey = result.problemKey
    }
    
    // MARK: - 回路操作
    
    /// ゲートを追加
    public func addGate(_ gate: QuantumGate) {
        guard state == .playing else { return }
        guard currentCircuit.addGate(gate) else { return }
        
        // 現在の状態を計算（開始状態から）
        guard let problem = currentProblem else { return }
        let currentState = currentCircuit.apply(to: problem.startState)
        currentVector = BlochVector(from: currentState)
    }
    
    /// ゲートを削除
    public func removeGate(at index: Int) {
        guard state == .playing else { return }
        currentCircuit.removeGate(at: index)
        
        // 現在の状態を再計算（開始状態から）
        guard let problem = currentProblem else { return }
        let currentState = currentCircuit.apply(to: problem.startState)
        currentVector = BlochVector(from: currentState)
    }
    
    /// 回路をクリア
    public func clearCircuit() {
        guard state == .playing else { return }
        currentCircuit.clear()
        // 開始状態に戻す
        if let problem = currentProblem {
            currentVector = problem.startBlochVector
        } else {
            currentVector = .zero
        }
    }
    
    // MARK: - Run判定用メソッド
    
    /// 現在の状態がターゲットと一致するか判定（Runボタン用）
    public func checkCurrentState() -> Bool {
        guard let problem = currentProblem else { return false }
        
        let result = judgeService.judge(
            playerCircuit: currentCircuit,
            startState: problem.startState,
            targetState: problem.targetState
        )
        
        return result.isCorrect
    }
    
    /// 正解処理を実行（Runボタン用）
    public func handleCorrectAnswer() {
        guard currentProblem != nil else { return }
        
        // コンボ加算
        comboCount += 1
        
        // 基本スコア
        let baseScore = (gameDifficulty == .hard) ? 200 : 100

        // シグモイド関数によるコンボボーナス計算
        let bonus: Int
        if comboCount >= 2 {
            let maxBonus: Double = (gameDifficulty == .hard) ? 300.0 : 150.0
            let k: Double = 0.5 // 傾き（急峻さ）
            let midpoint: Double = 8.0 // 変曲点（このコンボ数でMaxの半分になる）
            let x = Double(comboCount)
            
            let sigmoidValue = 1.0 / (1.0 + exp(-k * (x - midpoint)))
            bonus = Int(maxBonus * sigmoidValue)
        } else {
            bonus = 0
        }
        
        let comboBonus = bonus
        
        // UI表示用に保持
        lastComboBonus = comboBonus
        
        // スコア加算
        score += baseScore + comboBonus
        problemsSolved += 1
        
        didSolveLastProblem = true
        
        // 回路をクリアして次の問題へ
        currentCircuit.clear()
        generateNewProblem()
        // 新しい問題の開始状態に設定
        if let newProblem = currentProblem {
            currentVector = newProblem.startBlochVector
        }
        
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            self.didSolveLastProblem = false
        }
    }
    
    /// お手つき処理を実行（Runボタン用）
    public func handleWrongAnswer() -> Bool {
        // コンボリセット
        comboCount = 0
        lastComboBonus = 0
        
        // ミスしてもゲームオーバーにはならない
        return false
    }
}
