import Foundation

/// 回路実行後の正誤判定結果
public struct JudgeResult: Sendable {
    public let isCorrect: Bool

    public let fidelity: Double
}
