import Foundation

/// 1量子ビットの状態を表す値型．α|0⟩ + β|1⟩ の形式で正規化された振幅を保持
public struct QuantumState: Sendable, Equatable {

    /// |0⟩ の振幅
    public let alpha: Complex

    /// |1⟩ の振幅
    public let beta: Complex

    public init(alpha: Complex, beta: Complex) {
        // norm = √(|α|² + |β|²)
        let norm = (alpha.magnitudeSquared + beta.magnitudeSquared).squareRoot()

        if norm > 0 {
            // α' = α / norm, β' = β / norm
            // → |α'|² + |β'|² = 1 (正規化条件)
            self.alpha = Complex(
                real: alpha.real / norm,
                imaginary: alpha.imaginary / norm
            )
            self.beta = Complex(
                real: beta.real / norm,
                imaginary: beta.imaginary / norm
            )
        } else {
            // ゼロベクトル → |0⟩ にフォールバック
            self.alpha = .one
            self.beta = .zero
        }
    }

    /// |0⟩
    public static let zero = QuantumState(alpha: .one, beta: .zero)

    /// |1⟩
    public static let one = QuantumState(alpha: .zero, beta: .one)

    /// |+⟩ = (|0⟩ + |1⟩)/√2
    // α = β = 1/√2 (X基底の固有状態, 固有値+1)
    public static let plus = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot()),
        beta: Complex(real: 1.0 / 2.0.squareRoot())
    )

    /// |−⟩ = (|0⟩ − |1⟩)/√2
    // α = 1/√2, β = -1/√2 (X基底の固有状態, 固有値-1)
    public static let minus = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot()),
        beta: Complex(real: -1.0 / 2.0.squareRoot())
    )

    /// |+i⟩ = (|0⟩ + i|1⟩)/√2
    // α = 1/√2, β = i/√2 (Y基底の固有状態, 固有値+1)
    public static let plusI = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot()),
        beta: Complex(real: 0, imaginary: 1.0 / 2.0.squareRoot())
    )

    /// |−i⟩ = (|0⟩ − i|1⟩)/√2
    // α = 1/√2, β = -i/√2 (Y基底の固有状態, 固有値-1)
    public static let minusI = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot()),
        beta: Complex(real: 0, imaginary: -1.0 / 2.0.squareRoot())
    )

    // T(θ) 状態: |+⟩ に位相 e^{iθ} を適用 → (1/√2)(|0⟩ + e^{iθ}|1⟩)
    // β = e^{iπ/4}/√2 = (cos(π/4) + i·sin(π/4))/√2
    public static let t45 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(Double.pi / 4) / 2.0.squareRoot()
        )
    )

    // β = e^{i·3π/4}/√2 = (cos(3π/4) + i·sin(3π/4))/√2
    public static let t135 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(3 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(3 * Double.pi / 4) / 2.0.squareRoot()
        )
    )

    // β = e^{i·5π/4}/√2 = (cos(5π/4) + i·sin(5π/4))/√2
    public static let t225 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(5 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(5 * Double.pi / 4) / 2.0.squareRoot()
        )
    )

    // β = e^{i·7π/4}/√2 = (cos(7π/4) + i·sin(7π/4))/√2
    public static let t315 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(7 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(7 * Double.pi / 4) / 2.0.squareRoot()
        )
    )

    // Rx(θ)|0⟩ = cos(θ/2)|0⟩ - i·sin(θ/2)|1⟩
    // θ=π/4 → α = cos(π/8), β = -i·sin(π/8)
    public static let rx45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: -sin(Double.pi / 8))
    )

    // θ=3π/4 → α = cos(3π/8), β = -i·sin(3π/8)
    public static let rx135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: -sin(3 * Double.pi / 8))
    )

    // Rx(-θ)|0⟩ = cos(θ/2)|0⟩ + i·sin(θ/2)|1⟩
    // θ=π/4 → α = cos(π/8), β = +i·sin(π/8)
    public static let rx_45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: sin(Double.pi / 8))
    )

    // θ=3π/4 → α = cos(3π/8), β = +i·sin(3π/8)
    public static let rx_135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: sin(3 * Double.pi / 8))
    )

    // Ry(θ)|0⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩
    // θ=π/4 → α = cos(π/8), β = sin(π/8)
    public static let ry45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: sin(Double.pi / 8), imaginary: 0)
    )

    // Ry(-θ)|0⟩ = cos(θ/2)|0⟩ - sin(θ/2)|1⟩
    // θ=π/4 → α = cos(π/8), β = -sin(π/8)
    public static let ry_45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: -sin(Double.pi / 8), imaginary: 0)
    )

    // θ=3π/4 → α = cos(3π/8), β = sin(3π/8)
    public static let ry135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: sin(3 * Double.pi / 8), imaginary: 0)
    )

    // θ=3π/4 → α = cos(3π/8), β = -sin(3π/8)
    public static let ry_135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: -sin(3 * Double.pi / 8), imaginary: 0)
    )

    // Rx/Ry 状態に Tゲート (e^{iπ/4} 位相) を追加適用した複合状態
    // T·Rx(θ)|0⟩, T·Ry(θ)|0⟩
    public static let rx45_t = rx45.applying([.t])

    public static let rx_45_t = rx_45.applying([.t])

    public static let rx135_t = rx135.applying([.t])

    public static let rx_135_t = rx_135.applying([.t])

    public static let ry45_t = ry45.applying([.t])

    public static let ry_45_t = ry_45.applying([.t])

    public static let ry135_t = ry135.applying([.t])

    public static let ry_135_t = ry_135.applying([.t])

    // P(|0⟩) = |α|² (ボルンの規則)
    public var probabilityZero: Double {
        alpha.magnitudeSquared
    }

    // P(|1⟩) = |β|² (ボルンの規則)
    public var probabilityOne: Double {
        beta.magnitudeSquared
    }

    // ⟨ψ|φ⟩ = α*·α' + β*·β'
    // α* = αの共役複素数
    public func innerProduct(with other: QuantumState) -> Complex {
        let term1 = alpha.conjugate * other.alpha
        let term2 = beta.conjugate * other.beta
        return term1 + term2
    }

    // F(ψ, φ) = |⟨ψ|φ⟩|² ∈ [0, 1]
    // 1 → 完全一致, 0 → 直交（完全不一致）
    public func fidelity(with other: QuantumState) -> Double {
        innerProduct(with: other).magnitudeSquared
    }

    // Gₙ ··· G₂·G₁|ψ⟩ — ゲートを左から順に適用
    public func applying(_ gates: [QuantumGate]) -> QuantumState {
        gates.reduce(self) { state, gate in gate.apply(to: state) }
    }
}
