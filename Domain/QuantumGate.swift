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
        // X = [[0, 1], [1, 0]] — ビット反転
        case .x:
            return [
                [.zero, .one],
                [.one, .zero]
            ]
        // Y = [[0, -i], [i, 0]] — ビット反転 + 位相反転
        case .y:
            return [
                [.zero, Complex(real: 0, imaginary: -1)],
                [.i, .zero]
            ]
        // Z = [[1, 0], [0, -1]] — 位相反転
        case .z:
            return [
                [.one, .zero],
                [.zero, Complex(real: -1, imaginary: 0)]
            ]
        // H = (1/√2)[[1, 1], [1, -1]] — Z基底 ↔ X基底 の変換
        case .h:
            let factor = 1.0 / 2.0.squareRoot()
            return [
                [Complex(real: factor, imaginary: 0), Complex(real: factor, imaginary: 0)],
                [Complex(real: factor, imaginary: 0), Complex(real: -factor, imaginary: 0)]
            ]
        // S = [[1, 0], [0, i]] — π/2 位相ゲート (Z^{1/2})
        case .s:
            return [
                [.one, .zero],
                [.zero, .i]
            ]
        // T = [[1, 0], [0, e^{iπ/4}]] — π/8 ゲート (Z^{1/4})
        case .t:
            let angle = Double.pi / 4
            // e^{iπ/4} = cos(π/4) + i·sin(π/4)
            let phase = Complex(real: cos(angle), imaginary: sin(angle))
            return [
                [.one, .zero],
                [.zero, phase]
            ]
        }
    }

    // ブロッホ球上の回転: R_n̂(θ) = e^{-iθn̂·σ/2}
    // (axis: 回転軸の単位ベクトル, angle: 回転角)
    public var blochRotation: (axis: simd_double3, angle: Double) {
        switch self {
        // X軸まわり π 回転
        case .x:
            return (simd_double3(1, 0, 0), .pi)
        // Y軸まわり π 回転
        case .y:
            return (simd_double3(0, 1, 0), .pi)
        // Z軸まわり π 回転
        case .z:
            return (simd_double3(0, 0, 1), .pi)
        // (X+Z)/√2 軸まわり π 回転
        case .h:
            let factor = 1.0 / 2.0.squareRoot()
            let axis = simd_double3(factor, 0, factor)
            return (axis, .pi)
        // Z軸まわり π/2 回転
        case .s:
            return (simd_double3(0, 0, 1), .pi / 2)
        // Z軸まわり π/4 回転
        case .t:
            return (simd_double3(0, 0, 1), .pi / 4)
        }
    }

    // |ψ'⟩ = U|ψ⟩ — 行列積を展開して直接計算
    public func apply(to state: QuantumState) -> QuantumState {
        switch self {
        // X|ψ⟩ = β|0⟩ + α|1⟩ — α と β を交換
        case .x:
            return QuantumState(alpha: state.beta, beta: state.alpha)
        // Y|ψ⟩ = -i·β*|0⟩ + i·α*|1⟩
        // -i·(a+bi) = b - ai, i·(a+bi) = -b + ai
        case .y:
            return QuantumState(
                alpha: Complex(real: state.beta.imaginary, imaginary: -state.beta.real),
                beta: Complex(real: -state.alpha.imaginary, imaginary: state.alpha.real)
            )
        // Z|ψ⟩ = α|0⟩ - β|1⟩ — β の符号反転
        case .z:
            return QuantumState(
                alpha: state.alpha,
                beta: Complex(real: -state.beta.real, imaginary: -state.beta.imaginary)
            )
        // H|ψ⟩ = (1/√2)((α+β)|0⟩ + (α-β)|1⟩)
        case .h:
            let f = 1.0 / 2.0.squareRoot()
            return QuantumState(
                alpha: (state.alpha + state.beta) * f,
                beta: (state.alpha - state.beta) * f
            )
        // S|ψ⟩ = α|0⟩ + i·β|1⟩
        // i·(a+bi) = -b + ai
        case .s:
            return QuantumState(
                alpha: state.alpha,
                beta: Complex(real: -state.beta.imaginary, imaginary: state.beta.real)
            )
        // T|ψ⟩ = α|0⟩ + e^{iπ/4}·β|1⟩
        // e^{iπ/4}·(a+bi) = (ca - sb) + (cb + sa)i
        // ここで c = cos(π/4), s = sin(π/4)
        case .t: 
            let c = cos(Double.pi / 4)
            let s = sin(Double.pi / 4)
            return QuantumState(
                alpha: state.alpha,
                beta: Complex(
                    real: c * state.beta.real - s * state.beta.imaginary,
                    imaginary: c * state.beta.imaginary + s * state.beta.real
                )
            )
        }
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
