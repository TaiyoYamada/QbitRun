import Foundation

/// 複素数を表す値型
public struct Complex: Sendable, Equatable {
    public let real: Double

    public let imaginary: Double

    public init(real: Double, imaginary: Double = 0) {
        self.real = real
        self.imaginary = imaginary
    }

    public static let zero = Complex(real: 0, imaginary: 0)

    public static let one = Complex(real: 1, imaginary: 0)

    public static let i = Complex(real: 0, imaginary: 1)

    /// 絶対値 |z| = √(a² + b²)
    public var magnitude: Double {
        (real * real + imaginary * imaginary).squareRoot()
    }

    /// 絶対値の二乗 |z|² = a² + b²
    public var magnitudeSquared: Double {
        real * real + imaginary * imaginary
    }

    /// 共役複素数 z* = a - bi
    public var conjugate: Complex {
        Complex(real: real, imaginary: -imaginary)
    }

    /// 偏角 arg(z) = atan2(b, a)
    public var phase: Double {
        atan2(imaginary, real)
    }
}

extension Complex {

    /// (a+bi) + (c+di) = (a+c) + (b+d)i
    public static func + (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
    }

    /// (a+bi) - (c+di) = (a-c) + (b-d)i
    public static func - (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real - rhs.real, imaginary: lhs.imaginary - rhs.imaginary)
    }

    /// (a+bi)(c+di)
    /// = (ac - bd) + (ad + bc)i
    public static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(
            real: lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
            imaginary: lhs.real * rhs.imaginary + lhs.imaginary * rhs.real
        )
    }

    // スカラー倍: k·(a+bi) = ka + kbi
    public static func * (lhs: Double, rhs: Complex) -> Complex {
        Complex(real: lhs * rhs.real, imaginary: lhs * rhs.imaginary)
    }

    // (a+bi)·k = ak + bki
    public static func * (lhs: Complex, rhs: Double) -> Complex {
        Complex(real: lhs.real * rhs, imaginary: lhs.imaginary * rhs)
    }
}
