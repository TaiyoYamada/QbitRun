import Foundation

// MARK: - 問題生成器

/// ブロッホ球の主要状態をターゲットにした問題を生成する
public struct ProblemGenerator: Sendable {
    
    // MARK: - 使用可能な状態
    
    /// 開始・終了状態として使用可能な量子状態
    /// ブロッホ球の主要10状態
    private let availableStates: [QuantumState] = [
        .zero, .one,                    // Z軸（北極・南極）
        .plus, .minus,                  // X軸
        .plusI, .minusI,                // Y軸
        .t45, .t135, .t225, .t315       // 45度刻みの位相
    ]
    
    // MARK: - 問題生成
    public func generateProblem(gameDifficulty: GameDifficulty, problemNumber: Int, lastProblemKey: String? = nil) -> (problem: Problem, problemKey: String) {
        return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, lastProblemKey: lastProblemKey)
    }
    
    // MARK: - ランダム問題生成
    
    /// ランダムな問題を生成
    private func generateRandomProblem(gameDifficulty: GameDifficulty, problemNumber: Int, lastProblemKey: String?, retryCount: Int = 0) -> (problem: Problem, problemKey: String) {
        // 無限ループ防止
        guard retryCount < 50 else {
            return (createFallbackProblem(problemNumber: problemNumber), "fallback")
        }
        
        // 開始状態を決定
        let startState: QuantumState
        switch gameDifficulty {
        case .easy:
            // Easy: 常に |0⟩ から開始
            startState = .zero
        case .hard:
            // Hard: ランダムな状態から開始
            startState = availableStates.randomElement()!
        }
        
        // 終了状態をランダムに選択
        let targetState = availableStates.randomElement()!
        
        // 同じ状態は避ける
        if startState.fidelity(with: targetState) > 0.99 {
            return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, lastProblemKey: lastProblemKey, retryCount: retryCount + 1)
        }
        
        // 直前と同じ問題（開始・終了ペア）を避ける
        let problemKey = "\(startState.probabilityZero)->\(targetState.probabilityZero)"
        if let lastKey = lastProblemKey, lastKey == problemKey {
            return generateRandomProblem(gameDifficulty: gameDifficulty, problemNumber: problemNumber, lastProblemKey: lastProblemKey, retryCount: retryCount + 1)
        }
        
        let problem = Problem(
            startState: startState,
            startBlochVector: BlochVector(from: startState),
            targetState: targetState,
            targetBlochVector: BlochVector(from: targetState),
            minimumGates: 1,
            referenceSolution: [],
            difficulty: problemNumber
        )
        
        return (problem, problemKey)
    }
    
    /// フォールバック問題
    private func createFallbackProblem(problemNumber: Int) -> Problem {
        return Problem(
            startState: .zero,
            startBlochVector: .zero,
            targetState: .one,
            targetBlochVector: .one,
            minimumGates: 1,
            referenceSolution: [.x],
            difficulty: problemNumber
        )
    }
}
