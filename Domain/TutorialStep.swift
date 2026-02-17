import Foundation
import simd

public enum TutorialStep: CaseIterable, Equatable, Sendable {
    case intro
    case xGate
    case yGate
    case zGate
    case hGate
    case sGate
    case tGate
    case finish

    var title: String {
        switch self {
        case .intro: return "TUTORIAL"
        case .xGate: return "X GATE"
        case .yGate: return "Y GATE"
        case .zGate: return "Z GATE"
        case .hGate: return "H GATE"
        case .sGate: return "S GATE"
        case .tGate: return "T GATE"
        case .finish: return "READY TO LAUNCH"
        }
    }

    var instruction: String {
        switch self {
        case .intro:
        return "This 'Bloch sphere' represents a qubit — the basic unit of quantum computing.\n\n|0⟩ and |1⟩ are on the Z-axis (top and bottom).\n|+⟩ and |−⟩ on X, |+i⟩ and |−i⟩ on Y.\n\nThe arrow shows your current state.\nApply gates to rotate it toward the target."

        case .xGate:
        return "Flips the state top ↔ bottom.\n180° rotation around the X-axis.\n|0⟩ becomes |1⟩, and vice versa."

        case .yGate:
        return "Flips the state with a phase twist.\n180° rotation around the Y-axis.\nSimilar to X, but adds extra phase."

        case .zGate:
        return "Reverses the phase of the state.\n180° rotation around the Z-axis.\n|+⟩ becomes |−⟩, and vice versa."

        case .hGate:
        return "Creates superposition — an equal mix of 0 and 1.\nMoves the state between the pole and the equator.\n|0⟩ becomes |+⟩."

        case .sGate:
        return "A quarter turn around the Z-axis.\n90° phase rotation.\n|+⟩ becomes |+i⟩."

        case .tGate:
        return "A fine phase adjustment.\n45° rotation around the Z-axis.\nSlightly shifts the state along the equator."

        case .finish:
        return "You've learned all the basic gates!\nYou're ready to take on quantum puzzles."
        }
    }

    var targetGate: QuantumGate? {
        switch self {
        case .intro, .finish: return nil
        case .xGate: return .x
        case .yGate: return .y
        case .zGate: return .z
        case .hGate: return .h
        case .sGate: return .s
        case .tGate: return .t
        }
    }

    var initialVector: BlochVector {
        switch self {
        case .intro, .finish: return .zero
        case .xGate: return .zero
        case .yGate: return .plus
        case .zGate: return .plus
        case .hGate: return .zero
        case .sGate: return .plus
        case .tGate: return .plus
        }
    }
}
