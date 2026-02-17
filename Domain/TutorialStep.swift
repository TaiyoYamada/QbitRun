import Foundation
import simd

public enum TutorialStep: CaseIterable, Equatable, Sendable {
    case intro1
    case intro2
    case xGate1
    case xGate2
    case yGate1
    case yGate2
    case zGate1
    case zGate2
    case hGate1
    case hGate2
    case hGate3
    case sGate
    case tGate
    case finish

    var title: String {
        switch self {
        case .intro1, .intro2: return "BLOCH SPHERE"
        case .xGate1, .xGate2: return "X GATE"
        case .yGate1, .yGate2: return "Y GATE"
        case .zGate1, .zGate2: return "Z GATE"
        case .hGate1, .hGate2, .hGate3: return "H GATE"
        case .sGate: return "S GATE"
        case .tGate: return "T GATE"
        case .finish: return "READY TO LAUNCH"
        }
    }

    var instruction: String {
        switch self {
        case .intro1:
        return "This 'Bloch sphere' represents a quantum bit (qubit) — the basic unit of quantum computing.\n\nThe arrow shows your current quantum state."

        case .intro2:
        return "|0⟩ and |1⟩ are on the Z-axis (top and bottom).\n|+⟩ and |−⟩ on X, |+i⟩ and |−i⟩ on Y.\n\nApply gates to rotate the state toward the target."

        case .xGate1:
        return "Flips the state top ↔ bottom.\n180° rotation around the X-axis.\n|0⟩ becomes |1⟩, and vice versa."

        case .xGate2:
        return "Now try X from a different starting point.\nNotice how it flips around the X-axis.\n|+i⟩ becomes |−i⟩."

        case .yGate1:
        return "Flips the state with a phase twist.\n180° rotation around the Y-axis.\n|0⟩ becomes |1⟩."

        case .yGate2:
        return "Now try Y from the equator.\n|+⟩ becomes |−⟩.\nCompare how this differs from X."

        case .zGate1:
        return "Reverses the phase of the state.\n180° rotation around the Z-axis.\n|+⟩ becomes |−⟩, and vice versa."

        case .zGate2:
        return "Try Z from another equatorial state.\n|+i⟩ becomes |−i⟩.\nZ rotates states along the equator."

        case .hGate1:
        return "Creates superposition — an equal mix of 0 and 1.\nMoves the state between the pole and the equator.\n|0⟩ becomes |+⟩."

        case .hGate2:
        return "Now try H on an equatorial state.\n|+i⟩ becomes |−i⟩.\nH doesn't always create superposition!"

        case .hGate3:
        return "H on a diagonal equatorial state.\nWatch how the state moves to a new position.\nH is a 180° rotation around the (X+Z) axis."

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
        case .intro1, .intro2, .finish: return nil
        case .xGate1, .xGate2: return .x
        case .yGate1, .yGate2: return .y
        case .zGate1, .zGate2: return .z
        case .hGate1, .hGate2, .hGate3: return .h
        case .sGate: return .s
        case .tGate: return .t
        }
    }

    var initialVector: BlochVector {
        switch self {
        case .intro1, .intro2, .finish: return .zero
        case .xGate1: return .zero
        case .xGate2: return .plusI
        case .yGate1: return .zero
        case .yGate2: return .plus
        case .zGate1: return .plus
        case .zGate2: return .plusI
        case .hGate1: return .zero
        case .hGate2: return .plusI
        case .hGate3: return BlochVector(x: 1, y: 1, z: 0)
        case .sGate: return .plus
        case .tGate: return .plus
        }
    }
}
