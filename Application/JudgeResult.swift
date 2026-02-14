import Foundation

// MARK: - 判定結果

/// 正誤判定の結果
public struct JudgeResult: Sendable {
    /// 正解かどうか
    public let isCorrect: Bool
    
    /// フィデリティ値（0〜1）
    public let fidelity: Double
    
    /// フィードバックメッセージ
    public let message: String
}
