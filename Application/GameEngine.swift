// SPDX-License-Identifier: MIT
// Application/GameEngine.swift
// ゲームのコアロジック（タイマー、スコア、状態管理）

import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GameEngineの役割
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ゲームの「ビジネスロジック」を担当する（UIは知らない）
//
// 責務:
// - 60秒タイマーの管理
// - スコア計算
// - 問題生成・正解判定
// - 回路（ゲートリスト）の管理
// - ゲーム状態（ready/playing/paused/finished）の遷移
//
// @Observable を使用することで、SwiftUI Viewが自動的に状態変化を検知
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - ゲーム状態

/// ゲームの状態を表す列挙型
public enum GameState: Sendable {
    case ready      // 開始待ち
    case playing    // プレイ中
    case paused     // 一時停止
    case finished   // 終了
}

// MARK: - ゲームエンジン

/// ゲームのコアロジックを管理
/// @Observable: SwiftUIが自動的に状態変化を検知できる
/// @MainActor: UIスレッドで動作することを保証
@Observable
@MainActor
public final class GameEngine {
    
    // MARK: - 定数
    
    /// ゲーム時間（60秒）
    private let gameDuration: TimeInterval = 60
    
    /// 1問あたりの基本スコア
    private let baseScorePerProblem = 100
    
    /// お手つきの上限
    private let maxMisses = 3
    
    // MARK: - 公開プロパティ（SwiftUI Viewが監視）
    
    /// 現在のゲーム状態
    public private(set) var state: GameState = .ready
    
    /// 残り時間（秒）
    public private(set) var remainingTime: Int = 60
    
    /// 現在のスコア
    public private(set) var score: Int = 0
    
    /// 解いた問題数
    public private(set) var problemsSolved: Int = 0
    
    /// 獲得したボーナス合計
    public private(set) var totalBonus: Int = 0
    
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
    
    /// 正解判定サービス
    private let judgeService = JudgeService()
    
    /// タイマー用のTask
    private var timerTask: Task<Void, Never>?
    
    // MARK: - ゲーム制御
    
    /// ゲームを開始
    /// - Parameter difficulty: ゲームの難易度
    public func start(difficulty: GameDifficulty = .easy) {
        guard state == .ready else { return }
        
        // 難易度を設定
        self.gameDifficulty = difficulty
        
        // 状態をリセット
        state = .playing
        remainingTime = Int(gameDuration)
        score = 0
        problemsSolved = 0
        totalBonus = 0
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
        
        // タイマーを開始
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
        totalBonus = 0
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
            bonusPoints: totalBonus
        )
    }
    
    // MARK: - タイマー
    
    /// タイマーを開始（Swift Concurrencyを使用）
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
        currentProblem = problemGenerator.generateProblem(gameDifficulty: gameDifficulty, problemNumber: problemsSolved)
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
    
    // MARK: - 正解判定
    
    /// 現在の状態がターゲットと一致するか判定
    private func checkSolution(currentState: QuantumState) {
        guard let problem = currentProblem else { return }
        
        let result = judgeService.judge(
            playerCircuit: currentCircuit,
            startState: problem.startState,
            targetState: problem.targetState
        )
        
        if result.isCorrect {
            // 正解！
            let bonus = calculateBonus()
            score += baseScorePerProblem + bonus
            totalBonus += bonus
            problemsSolved += 1
            
            // 正解フラグを立てる（アニメーション用）
            didSolveLastProblem = true
            
            // 回路をクリアして次の問題へ
            currentCircuit.clear()
            generateNewProblem()
            // 新しい問題の開始状態に設定
            if let newProblem = currentProblem {
                currentVector = newProblem.startBlochVector
            }
            
            // 少し後にフラグをリセット
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                self.didSolveLastProblem = false
            }
        }
    }
    
    /// ボーナスを計算
    /// 最小ゲート数に近いほど高ボーナス
    private func calculateBonus() -> Int {
        guard let problem = currentProblem else { return 0 }
        
        let gatesUsed = currentCircuit.gateCount
        let minGates = problem.minimumGates
        
        if gatesUsed <= minGates {
            // 最適解または最適解より短い場合
            return 50
        } else if gatesUsed == minGates + 1 {
            return 25
        } else if gatesUsed == minGates + 2 {
            return 10
        }
        
        return 0
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
        
        let bonus = calculateBonus()
        score += baseScorePerProblem + bonus
        totalBonus += bonus
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
    /// - Returns: ゲームオーバーかどうか
    public func handleWrongAnswer() -> Bool {
        missCount += 1
        
        // 3回ミスでゲームオーバー
        if missCount >= maxMisses {
            endGame()
            return true
        }
        
        return false
    }
    
    /// 残りミス回数
    public var remainingMisses: Int {
        max(0, maxMisses - missCount)
    }
}
