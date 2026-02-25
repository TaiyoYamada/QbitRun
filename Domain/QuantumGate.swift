import Foundation
import simd
/// 量子ゲートを表す列挙型．各ゲートはユニタリ行列とブロッホ球上の回転として定義
public enum QuantumGate: String, CaseIterable, Sendable, Codable, Hashable {
    case x
    case y
    case z
    case h
    case s
    case t

    public var matrix: [[Complex]] {
        switch self {
        case .x:
            return [
                [.zero, .one],
                [.one, .zero]
            ]
        case .y:
            return [
                [.zero, Complex(real: 0, imaginary: -1)],
                [.i, .zero]
            ]
        case .z:
            return [
                [.one, .zero],
                [.zero, Complex(real: -1, imaginary: 0)]
            ]
        case .h:
            let factor = 1.0 / 2.0.squareRoot()
            return [
                [Complex(real: factor, imaginary: 0), Complex(real: factor, imaginary: 0)],
                [Complex(real: factor, imaginary: 0), Complex(real: -factor, imaginary: 0)]
            ]
        case .s:
            return [
                [.one, .zero],
                [.zero, .i]
            ]
        case .t:
            let angle = Double.pi / 4
            let phase = Complex(real: cos(angle), imaginary: sin(angle))
            return [
                [.one, .zero],
                [.zero, phase]
            ]
        }
    }

    public var blochRotation: (axis: simd_double3, angle: Double) {
        switch self {
        case .x:
            return (simd_double3(1, 0, 0), .pi)
        case .y:
            return (simd_double3(0, 1, 0), .pi)
        case .z:
            return (simd_double3(0, 0, 1), .pi)
        case .h:
            let factor = 1.0 / 2.0.squareRoot()
            let axis = simd_double3(factor, 0, factor)
            return (axis, .pi)
        case .s:
            return (simd_double3(0, 0, 1), .pi / 2)
        case .t:
            return (simd_double3(0, 0, 1), .pi / 4)
        }
    }

    public func apply(to state: QuantumState) -> QuantumState {
        let m = matrix
        let newAlpha = m[0][0] * state.alpha + m[0][1] * state.beta
        let newBeta = m[1][0] * state.alpha + m[1][1] * state.beta
        return QuantumState(alpha: newAlpha, beta: newBeta)
    }

    public var name: String {
        switch self {
        case .x: return "Pauli-X"
        case .y: return "Pauli-Y"
        case .z: return "Pauli-Z"
        case .h: return "Hadamard"
        case .s: return "S Gate"
        case .t: return "T Gate"
        }
    }

    public var description: String {
        switch self {
        case .x: return "π rotation around the X-axis (Rₓ(π)); maps |0⟩ ↔ |1⟩"
        case .y: return "π rotation around the Y-axis (Rᵧ(π)); maps |0⟩ → |1⟩ up to a global phase"
        case .z: return "π rotation around the Z-axis (R_z(π)); applies a phase of −1 to |1⟩"
        case .h: return "π rotation around the (X+Z)/√2 axis; swaps Z and X bases"
        case .s: return "π/2 rotation around the Z-axis (R_z(π/2)); phase gate"
        case .t: return "π/4 rotation around the Z-axis (R_z(π/4)); π/8 phase gate"
        }
    }
}
