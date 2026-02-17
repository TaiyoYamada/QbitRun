
import Foundation

public enum GameDifficulty: String, CaseIterable, Sendable, Codable {
    case easy
    case hard
    case expert

    public var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    public var description: String {
        switch self {
        case .easy: return "Start from |0⟩"
        case .hard: return "Random start"
        case .expert: return "Advanced States"
        }
    }
}
