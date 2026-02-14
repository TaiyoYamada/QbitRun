import Foundation

// MARK: - 問題データ

/// ゲームの1問を表す構造体
public struct Problem: Sendable {
    /// 開始する量子状態（ここからスタート）
    public let startState: QuantumState
    
    /// 開始のブロッホベクトル（可視化用）
    public let startBlochVector: BlochVector
    
    /// 目標とする量子状態
    public let targetState: QuantumState
    
    /// 目標のブロッホベクトル（可視化用）
    public let targetBlochVector: BlochVector
    
    /// 最小必要ゲート数（ボーナス計算用）
    public let minimumGates: Int
    
    /// 正解の一例（参考用、デバッグ用）
    public let referenceSolution: [QuantumGate]
    
    /// 難易度（0から始まり増加）
    public let difficulty: Int
}
