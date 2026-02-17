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
        return "This is the Bloch sphere — a geometric representation of a single qubit.\nA pure state lies on its surface.\n\nReference axes:\n|0⟩ (Z), |+⟩ (X), |+i⟩ (Y)\n\nApply quantum gates to rotate the state and reach the target."

        case .xGate:
        return "Apply the X gate.\nRotate 180° around the X-axis.\nFlips the Z component.\n|0⟩ ↔ |1⟩"

        case .yGate:
        return "Apply the Y gate.\nRotate 180° around the Y-axis.\nFlips X and Z components (adds phase).\n|0⟩ → i|1⟩"

        case .zGate:
        return "Apply the Z gate.\nRotate 180° around the Z-axis.\nPreserves Z, flips X and Y.\n|+⟩ ↔ |−⟩"

        case .hGate:
        return "Apply the H gate.\nMaps Z-basis to X-basis.\n|0⟩ → |+⟩\nCreates superposition."

        case .sGate:
        return "Apply the S gate.\nRotate 90° around the Z-axis.\n|+⟩ → |+i⟩"

        case .tGate:
        return "Apply the T gate.\nRotate 45° around the Z-axis.\nAdds phase e^{iπ/4} to |1⟩."

        case .finish:
        return "Calibration complete.\nYou can now control a qubit on the Bloch sphere."
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
