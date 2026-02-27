import Foundation

/// チュートリアルの各ステップを表す列挙型
public enum TutorialStep: CaseIterable, Equatable, Sendable {
    case intro1
    case intro2
    case intro3
    case intro4
    case xGate1
    case xGate2
    case yGate1
    case yGate2
    case zGate1
    case zGate2
    case hGate1
    case hGate2
    case sGate
    case tGate
    case finish

    func title(isReviewMode: Bool) -> String {
        switch self {
        case .intro1, .intro2, .intro3, .intro4: return "BLOCH SPHERE"
        case .xGate1, .xGate2: return "X GATE"
        case .yGate1, .yGate2: return "Y GATE"
        case .zGate1, .zGate2: return "Z GATE"
        case .hGate1, .hGate2: return "H GATE"
        case .sGate: return "S GATE"
        case .tGate: return "T GATE"
        case .finish: return isReviewMode ? "COMPLETE" : "READY"
        }
    }

    func instruction(isReviewMode: Bool) -> String {
        switch self {
        case .intro1:
        return "This Bloch sphere represents a quantum bit (qubit)\n— the basic unit of quantum computing.\n\nThe arrow shows your current quantum state."

        case .intro2:
        return "You can swipe the sphere to view it from any angle.\n\nTry it now!"

        case .intro3:
        return "|0⟩ and |1⟩ are on the Z-axis (top and bottom).\n|+⟩ and |−⟩ are on the X-axis.\n|+i⟩ and |−i⟩ are on the Y-axis."

        case .intro4:
        return "These 6 colored buttons are quantum gates.\n\nChain them together to move the arrow to a new position."


        case .xGate1:
        return "180° rotation around the X-axis.\nFlips the state top ↔ bottom.\n|0⟩ becomes |1⟩, and |1⟩ becomes |0⟩."

        case .xGate2:
        return "Now try X from a different starting point.\nThe same rotation, but a different result.\n|+i⟩ becomes |−i⟩."

        case .yGate1:
        return "180° rotation around the Y-axis.\nFlips the state with a phase twist.\n|0⟩ becomes |1⟩."

        case .yGate2:
        return "Now try Y from the equator. |+⟩ becomes |−⟩.\nCompare how this differs from X."

        case .zGate1:
        return "180° rotation around the Z-axis.\nReverses the phase of the state.\n|+⟩ becomes |−⟩, and |−⟩ becomes |+⟩."

        case .zGate2:
        return "Now try Z from another equatorial state.\nThe same rotation, but a different result.\n|+i⟩ becomes |−i⟩."

        case .hGate1:
        return "180° rotation around the (X+Z) axis.\nCreates superposition — an equal mix of 0 and 1.\n|0⟩ becomes |+⟩."

        case .hGate2:
        return "H on a diagonal equatorial state.\nWatch how the state moves to a new position.\nH is a 180° rotation around the (X+Z) axis."

        case .sGate:
        return "90° rotation around the Z-axis.\nA quarter turn of phase.\n|+⟩ becomes |+i⟩."

        case .tGate:
        return "45° rotation around the Z-axis.\nA fine phase adjustment.\nSlightly shifts the state along the equator."

        case .finish:
            if isReviewMode {
                return "That's all the gates!\nHead back anytime to review."
            } else {
                return "You've learned all the basic gates!\nNext, let's look at the game rules."
            }
        }
    }

    var targetGate: QuantumGate? {
        switch self {
        case .intro1, .intro2, .intro3, .intro4, .finish: return nil
        case .xGate1, .xGate2: return .x
        case .yGate1, .yGate2: return .y
        case .zGate1, .zGate2: return .z
        case .hGate1, .hGate2: return .h
        case .sGate: return .s
        case .tGate: return .t
        }
    }

    var initialVector: BlochVector {
        switch self {
        case .intro1, .intro2, .intro3, .intro4, .finish: return .zero
        case .xGate1: return .zero
        case .xGate2: return .plusI
        case .yGate1: return .zero
        case .yGate2: return .plus
        case .zGate1: return .plus
        case .zGate2: return .plusI
        case .hGate1: return .zero
        case .hGate2: return BlochVector(x: 1, y: 1, z: 0)
        case .sGate: return .plus
        case .tGate: return .plus
        }
    }
}
