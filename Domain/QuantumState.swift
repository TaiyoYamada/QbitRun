import Foundation

/// 1量子ビットの状態を表す値型．α|0⟩ + β|1⟩ の形式で正規化された振幅を保持
public struct QuantumState: Sendable, Equatable {
    public let alpha: Complex

    public let beta: Complex

    public init(alpha: Complex, beta: Complex) {
        let norm = (alpha.magnitudeSquared + beta.magnitudeSquared).squareRoot()

        if norm > 0 {
            self.alpha = Complex(
                real: alpha.real / norm,
                imaginary: alpha.imaginary / norm
            )
            self.beta = Complex(
                real: beta.real / norm,
                imaginary: beta.imaginary / norm
            )
        } else {
            self.alpha = .one
            self.beta = .zero
        }
    }

    public static let zero = QuantumState(alpha: .one, beta: .zero)

    public static let one = QuantumState(alpha: .zero, beta: .one)

    public static let plus = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0)
    )

    public static let minus = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: -1.0 / 2.0.squareRoot(), imaginary: 0)
    )

    public static let plusI = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: 0, imaginary: 1.0 / 2.0.squareRoot())
    )

    public static let minusI = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: 0, imaginary: -1.0 / 2.0.squareRoot())
    )

    public static let t45 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(Double.pi / 4) / 2.0.squareRoot()
        )
    )

    public static let t135 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(3 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(3 * Double.pi / 4) / 2.0.squareRoot()
        )
    )

    public static let t225 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(5 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(5 * Double.pi / 4) / 2.0.squareRoot()
        )
    )

    public static let t315 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(7 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(7 * Double.pi / 4) / 2.0.squareRoot()
        )
    )

    public static let rx45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: -sin(Double.pi / 8))
    )

    public static let rx135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: -sin(3 * Double.pi / 8))
    )

    public static let rx_45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: sin(Double.pi / 8))
    )

    public static let rx_135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: sin(3 * Double.pi / 8))
    )

    public static let ry45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: sin(Double.pi / 8), imaginary: 0)
    )

    public static let ry_45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: -sin(Double.pi / 8), imaginary: 0)
    )

    public static let ry135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: sin(3 * Double.pi / 8), imaginary: 0)
    )

    public static let ry_135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: -sin(3 * Double.pi / 8), imaginary: 0)
    )

    public static let rx45_t = rx45.applying([.t])

    public static let rx_45_t = rx_45.applying([.t])

    public static let rx135_t = rx135.applying([.t])

    public static let rx_135_t = rx_135.applying([.t])

    public static let ry45_t = ry45.applying([.t])

    public static let ry_45_t = ry_45.applying([.t])

    public static let ry135_t = ry135.applying([.t])

    public static let ry_135_t = ry_135.applying([.t])

    public var probabilityZero: Double {
        alpha.magnitudeSquared
    }

    public var probabilityOne: Double {
        beta.magnitudeSquared
    }

    public func innerProduct(with other: QuantumState) -> Complex {
        let term1 = alpha.conjugate * other.alpha
        let term2 = beta.conjugate * other.beta
        return term1 + term2
    }

    public func fidelity(with other: QuantumState) -> Double {
        innerProduct(with: other).magnitudeSquared
    }

    public func applying(_ gates: [QuantumGate]) -> QuantumState {
        gates.reduce(self) { state, gate in gate.apply(to: state) }
    }
}
