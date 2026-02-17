import Foundation

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

    public func apply(to state: QuantumState) -> QuantumState {
        let m = matrix
        let newAlpha = m[0][0] * state.alpha + m[0][1] * state.beta
        let newBeta = m[1][0] * state.alpha + m[1][1] * state.beta
        return QuantumState(alpha: newAlpha, beta: newBeta)
    }

    public var name: String {
        switch self {
        case .x: return "パウリX（NOT）"
        case .y: return "パウリY"
        case .z: return "パウリZ"
        case .h: return "アダマール"
        case .s: return "Sゲート（√Z）"
        case .t: return "Tゲート（√S）"
        }
    }

    public var description: String {
        switch self {
        case .x: return "ビット反転: |0⟩ ↔ |1⟩"
        case .y: return "Y軸周りの180°回転"
        case .z: return "位相反転: |1⟩ → -|1⟩"
        case .h: return "重ね合わせ: |0⟩ → |+⟩"
        case .s: return "90°位相シフト"
        case .t: return "45°位相シフト"
        }
    }
}
