// SPDX-License-Identifier: MIT
// Presentation/Game/GameViewModel.swift
// ゲーム画面のViewModel

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ViewModel とは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// MVVM (Model-View-ViewModel) パターンの中間層
//
// 責務:
// - Viewに表示するためのデータを保持
// - Viewからのユーザー操作を受け取りApplication層に委譲
// - Application層の状態変化をViewに橋渡し
//
// @Observable を使うとSwiftUI Viewが自動的に更新される
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
    
    // MARK: - 表示用プロパティ（GameEngineからの橋渡し）
    
    /// 残り時間（秒）
    var remainingTime: Int { gameEngine.remainingTime }
    
    /// スコア
    var score: Int { gameEngine.score }
    
    /// 解いた問題数
    var problemsSolved: Int { gameEngine.problemsSolved }
    
    /// 現在のブロッホベクトル
    var currentVector: BlochVector { gameEngine.currentVector }
    
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
    
    // MARK: - ユーザー操作
    
    /// ゲームを開始
    func startGame() {
        gameEngine.start()
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
    /// - Returns: 正解かどうか
    func runCircuit() -> Bool {
        // 現在の状態がターゲットに十分近いか判定
        let isCorrect = gameEngine.checkCurrentState()
        if isCorrect {
            gameEngine.handleCorrectAnswer()
        }
        return isCorrect
    }
}
