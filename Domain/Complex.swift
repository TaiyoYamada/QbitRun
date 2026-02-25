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

    public var magnitude: Double {
        (real * real + imaginary * imaginary).squareRoot()
    }

    public var magnitudeSquared: Double {
        real * real + imaginary * imaginary
    }

    public var conjugate: Complex {
        Complex(real: real, imaginary: -imaginary)
    }

    public var phase: Double {
        atan2(imaginary, real)
    }
}

extension Complex {
    public static func + (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
    }

    public static func - (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real - rhs.real, imaginary: lhs.imaginary - rhs.imaginary)
    }

    public static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(
            real: lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
            imaginary: lhs.real * rhs.imaginary + lhs.imaginary * rhs.real
        )
    }

    public static func * (lhs: Double, rhs: Complex) -> Complex {
        Complex(real: lhs * rhs.real, imaginary: lhs * rhs.imaginary)
    }

    public static func * (lhs: Complex, rhs: Double) -> Complex {
        Complex(real: lhs.real * rhs, imaginary: lhs.imaginary * rhs)
    }
}
