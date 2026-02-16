// ゲームの難易度設定

import Foundation

/// ゲームの難易度
public enum GameDifficulty: String, CaseIterable, Sendable, Codable {
    case easy   // Easy: 開始状態は常に |0⟩
    case hard   // Hard: 開始状態もランダム
    case expert // Expert: 複雑なターゲット状態も出現
    
    /// 表示名
    public var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
    
    /// 説明
    public var description: String {
        switch self {
        case .easy: return "Start from |0⟩"
        case .hard: return "Random start"
        case .expert: return "Advanced States"
        }
    }
}
