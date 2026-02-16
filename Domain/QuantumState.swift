import Foundation

// MARK: - 量子状態

public struct QuantumState: Sendable, Equatable {
    /// |0⟩ の確率振幅
    public let alpha: Complex
    
    /// |1⟩ の確率振幅
    public let beta: Complex
    
    // MARK: - イニシャライザ
    
    /// 確率振幅を指定して初期化（自動正規化）
    public init(alpha: Complex, beta: Complex) {
        // 正規化: |α|² + |β|² = 1 になるようにスケール
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
            // ゼロベクトルの場合は |0⟩ にフォールバック
            self.alpha = .one
            self.beta = .zero
        }
    }
    
    // MARK: - 基底状態（よく使う状態）
    
    /// |0⟩ 状態（計算基底、北極）
    /// 「0」を100%の確率で観測する状態
    public static let zero = QuantumState(alpha: .one, beta: .zero)
    
    /// |1⟩ 状態（計算基底、南極）
    /// 「1」を100%の確率で観測する状態
    public static let one = QuantumState(alpha: .zero, beta: .one)
    
    /// |+⟩ 状態（X軸正方向）
    /// (|0⟩ + |1⟩) / √2
    /// 0と1を50%ずつの確率で観測
    public static let plus = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0)
    )
    
    /// |-⟩ 状態（X軸負方向）
    /// (|0⟩ - |1⟩) / √2
    public static let minus = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: -1.0 / 2.0.squareRoot(), imaginary: 0)
    )
    
    /// |i⟩ 状態（Y軸正方向）
    /// (|0⟩ + i|1⟩) / √2
    public static let plusI = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: 0, imaginary: 1.0 / 2.0.squareRoot())
    )
    
    /// |-i⟩ 状態（Y軸負方向）
    /// (|0⟩ - i|1⟩) / √2
    public static let minusI = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(real: 0, imaginary: -1.0 / 2.0.squareRoot())
    )
    
    // MARK: - Tゲート用の状態（45度刻み）
    
    /// T|+⟩ 状態（XY平面上45度）
    /// (|0⟩ + e^(iπ/4)|1⟩) / √2
    /// H→Tで到達
    public static let t45 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(Double.pi / 4) / 2.0.squareRoot()
        )
    )
    
    /// T|+⟩を3回Tした状態（XY平面上135度）
    /// (|0⟩ + e^(i3π/4)|1⟩) / √2
    /// H→T→T→Tで到達
    public static let t135 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(3 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(3 * Double.pi / 4) / 2.0.squareRoot()
        )
    )
    
    /// XY平面上225度
    /// (|0⟩ + e^(i5π/4)|1⟩) / √2
    /// H→S→S→T で到達
    public static let t225 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(5 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(5 * Double.pi / 4) / 2.0.squareRoot()
        )
    )
    
    /// XY平面上315度
    /// (|0⟩ + e^(i7π/4)|1⟩) / √2
    /// H→S→S→S→T で到達
    public static let t315 = QuantumState(
        alpha: Complex(real: 1.0 / 2.0.squareRoot(), imaginary: 0),
        beta: Complex(
            real: cos(7 * Double.pi / 4) / 2.0.squareRoot(),
            imaginary: sin(7 * Double.pi / 4) / 2.0.squareRoot()
        )
    )
    // MARK: - Expert用状態（X軸回転）
    
    /// Rx(π/4)|0⟩ 状態（X軸周りに45度回転）
    /// H → T → H |0⟩ で到達
    /// 確率振幅: α = cos(π/8), β = -i sin(π/8)
    public static let rx45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: -sin(Double.pi / 8))
    )

    /// Rx(3π/4)|0⟩ 状態（X軸周りに135度回転）
    /// H → T → T → T → H |0⟩ で到達
    public static let rx135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: -sin(3 * Double.pi / 8))
    )
    
    /// Rx(-π/4)|0⟩ 状態（X軸周りに-45度回転）
    /// 確率振幅: α = cos(π/8), β = i sin(π/8)
    public static let rx_45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: sin(Double.pi / 8))
    )
    
    /// Rx(-3π/4)|0⟩ 状態（X軸周りに-135度回転）
    public static let rx_135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: 0, imaginary: sin(3 * Double.pi / 8))
    )
    
    // MARK: - Expert用状態（Y軸回転）
    
    /// Ry(π/4)|0⟩ 状態（Y軸周りに45度回転）
    /// S → H → T → H → S† |0⟩ で到達
    /// 確率振幅: α = cos(π/8), β = sin(π/8)
    public static let ry45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: sin(Double.pi / 8), imaginary: 0)
    )
    
    /// Ry(-π/4)|0⟩ 状態（Y軸周りに-45度回転）
    public static let ry_45 = QuantumState(
        alpha: Complex(real: cos(Double.pi / 8), imaginary: 0),
        beta: Complex(real: -sin(Double.pi / 8), imaginary: 0)
    )
    
    /// Ry(3π/4)|0⟩ 状態（Y軸周りに135度回転）
    public static let ry135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: sin(3 * Double.pi / 8), imaginary: 0)
    )
    
    /// Ry(-3π/4)|0⟩ 状態（Y軸周りに-135度回転）
    public static let ry_135 = QuantumState(
        alpha: Complex(real: cos(3 * Double.pi / 8), imaginary: 0),
        beta: Complex(real: -sin(3 * Double.pi / 8), imaginary: 0)
    )
    
    // MARK: - Expert用状態（対角回転・中間位相）
    // X/Y軸回転の状態にTゲート（Z軸45度回転）を適用したもの
    
    /// T Rx(π/4)|0⟩
    public static let rx45_t = rx45.applying([.t])
    
    /// T Rx(-π/4)|0⟩
    public static let rx_45_t = rx_45.applying([.t])
    
    /// T Rx(3π/4)|0⟩
    public static let rx135_t = rx135.applying([.t])
    
    /// T Rx(-3π/4)|0⟩
    public static let rx_135_t = rx_135.applying([.t])
    
    /// T Ry(π/4)|0⟩
    public static let ry45_t = ry45.applying([.t])
    
    /// T Ry(-π/4)|0⟩
    public static let ry_45_t = ry_45.applying([.t])
    
    /// T Ry(3π/4)|0⟩
    public static let ry135_t = ry135.applying([.t])
    
    /// T Ry(-3π/4)|0⟩
    public static let ry_135_t = ry_135.applying([.t])
    
    
    /// |0⟩ を観測する確率
    public var probabilityZero: Double {
        alpha.magnitudeSquared
    }
    
    /// |1⟩ を観測する確率
    public var probabilityOne: Double {
        beta.magnitudeSquared
    }
    
    // MARK: - 内積とフィデリティ
    
    /// 内積を計算: ⟨self|other⟩
    /// 量子状態の「似ている度合い」を測る
    public func innerProduct(with other: QuantumState) -> Complex {
        // ⟨ψ|φ⟩ = α*α' + β*β'  （*は複素共役）
        let term1 = alpha.conjugate * other.alpha
        let term2 = beta.conjugate * other.beta
        return term1 + term2
    }
    
    /// フィデリティ（忠実度）を計算: |⟨self|other⟩|²
    public func fidelity(with other: QuantumState) -> Double {
        innerProduct(with: other).magnitudeSquared
    }
    
    // MARK: - ゲート適用
    
    /// 量子ゲートの配列を順番に適用
    public func applying(_ gates: [QuantumGate]) -> QuantumState {
        gates.reduce(self) { state, gate in gate.apply(to: state) }
    }
}
