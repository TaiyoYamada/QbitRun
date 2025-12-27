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
// Clean Architectureでの位置:
// Application層 = ユースケース層
// Domainを使ってゲームルールを実装する
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - デリゲート

/// ゲームエンジンのイベントを通知するデリゲート
/// UIKitでは、オブジェクト間の通信にデリゲートパターンをよく使う
@MainActor
public protocol GameEngineDelegate: AnyObject {
    /// ゲーム開始時に呼ばれる
    func gameDidStart()
    
    /// タイマー更新時（毎秒）に呼ばれる
    func gameDidUpdateTime(remaining: TimeInterval)
    
    /// 問題を正解した時に呼ばれる
    func gameDidSolveProblem(score: Int, bonus: Int)
    
    /// 新しい問題が生成された時に呼ばれる
    func gameDidGenerateNewProblem(_ problem: Problem)
    
    /// 回路の状態が変わった時に呼ばれる
    func gameDidUpdateCurrentState(_ state: QuantumState, blochVector: BlochVector)
    
    /// ゲーム終了時に呼ばれる
    func gameDidFinish(finalScore: ScoreEntry)
}

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
/// @MainActor: UIスレッドで動作することを保証
@MainActor
public final class GameEngine {
    
    // MARK: - 定数
    
    /// ゲーム時間（60秒）
    private let gameDuration: TimeInterval = 60
    
    /// 1問あたりの基本スコア
    private let baseScorePerProblem = 100
    
    // MARK: - プロパティ
    
    /// デリゲート（イベント通知先）
    public weak var delegate: GameEngineDelegate?
    
    /// 現在のゲーム状態
    public private(set) var state: GameState = .ready
    
    /// 残り時間
    public private(set) var remainingTime: TimeInterval = 60
    
    /// 現在のスコア
    public private(set) var score: Int = 0
    
    /// 解いた問題数
    public private(set) var problemsSolved: Int = 0
    
    /// 獲得したボーナス合計
    public private(set) var totalBonus: Int = 0
    
    /// 現在の問題
    public private(set) var currentProblem: Problem?
    
    /// 現在の回路
    public private(set) var currentCircuit = Circuit()
    
    /// 問題生成器
    private let problemGenerator = ProblemGenerator()
    
    /// 正解判定サービス
    private let judgeService = JudgeService()
    
    /// タイマー用のTask
    private var timerTask: Task<Void, Never>?
    
    // MARK: - ゲーム制御
    
    /// ゲームを開始
    public func start() {
        guard state == .ready else { return }
        
        // 状態をリセット
        state = .playing
        remainingTime = gameDuration
        score = 0
        problemsSolved = 0
        totalBonus = 0
        currentCircuit = Circuit()
        
        // 最初の問題を生成
        generateNewProblem()
        
        // デリゲートに通知
        delegate?.gameDidStart()
        
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
    
    /// ゲームを終了
    private func endGame() {
        state = .finished
        timerTask?.cancel()
        
        // スコアエントリを作成
        let entry = ScoreEntry(
            score: score,
            problemsSolved: problemsSolved,
            bonusPoints: totalBonus
        )
        
        delegate?.gameDidFinish(finalScore: entry)
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
                self.delegate?.gameDidUpdateTime(remaining: self.remainingTime)
                
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
        currentProblem = problemGenerator.generateProblem(difficulty: problemsSolved)
        
        if let problem = currentProblem {
            delegate?.gameDidGenerateNewProblem(problem)
        }
    }
    
    // MARK: - 回路操作
    
    /// ゲートを追加
    public func addGate(_ gate: QuantumGate) {
        guard state == .playing else { return }
        guard currentCircuit.addGate(gate) else { return }
        
        // 現在の状態を計算
        let currentState = currentCircuit.apply(to: .zero)
        let blochVector = BlochVector(from: currentState)
        
        delegate?.gameDidUpdateCurrentState(currentState, blochVector: blochVector)
        
        // 正解判定
        checkSolution(currentState: currentState)
    }
    
    /// ゲートを削除
    public func removeGate(at index: Int) {
        guard state == .playing else { return }
        currentCircuit.removeGate(at: index)
        
        // 現在の状態を再計算
        let currentState = currentCircuit.apply(to: .zero)
        let blochVector = BlochVector(from: currentState)
        
        delegate?.gameDidUpdateCurrentState(currentState, blochVector: blochVector)
    }
    
    /// 回路をクリア
    public func clearCircuit() {
        guard state == .playing else { return }
        currentCircuit.clear()
        
        delegate?.gameDidUpdateCurrentState(.zero, blochVector: .zero)
    }
    
    // MARK: - 正解判定
    
    /// 現在の状態がターゲットと一致するか判定
    private func checkSolution(currentState: QuantumState) {
        guard let problem = currentProblem else { return }
        
        let result = judgeService.judge(
            playerCircuit: currentCircuit,
            targetState: problem.targetState
        )
        
        if result.isCorrect {
            // 正解！
            let bonus = calculateBonus()
            score += baseScorePerProblem + bonus
            totalBonus += bonus
            problemsSolved += 1
            
            delegate?.gameDidSolveProblem(score: score, bonus: bonus)
            
            // 回路をクリアして次の問題へ
            currentCircuit.clear()
            generateNewProblem()
        }
    }
    
    /// ボーナスを計算
    /// 最小ゲート数に近いほど高ボーナス
    private func calculateBonus() -> Int {
        guard let problem = currentProblem else { return 0 }
        
        let gatesUsed = currentCircuit.gateCount
        let minGates = problem.minimumGates
        
        if gatesUsed <= minGates {
            // 最適解または最適解より短い場合（理論上ない）
            return 50
        } else if gatesUsed == minGates + 1 {
            return 25
        } else if gatesUsed == minGates + 2 {
            return 10
        }
        
        return 0
    }
}
