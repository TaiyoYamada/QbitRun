import Foundation

// MARK: - 複素数

/// 量子力学で使用される複素数型
/// 実部と虚部で構成され、量子状態の振幅を表現する
public struct Complex: Sendable, Equatable {
    /// 実部（Real part）
    public let real: Double
    
    /// 虚部（Imaginary part）
    public let imaginary: Double
    
    // MARK: - イニシャライザ
    
    public init(real: Double, imaginary: Double = 0) {
        self.real = real
        self.imaginary = imaginary
    }
    
    // MARK: - 静的プロパティ
    
    /// 0（ゼロ）
    public static let zero = Complex(real: 0, imaginary: 0)
    
    /// 1（実数の1）
    public static let one = Complex(real: 1, imaginary: 0)
    
    /// i（虚数単位）
    public static let i = Complex(real: 0, imaginary: 1)
    
    // MARK: - 計算プロパティ
    
    /// 絶対値（ノルム）
    /// |a + bi| = √(a² + b²)
    public var magnitude: Double {
        (real * real + imaginary * imaginary).squareRoot()
    }
    
    /// 絶対値の2乗（確率計算に使用）
    /// |a + bi|² = a² + b²
    public var magnitudeSquared: Double {
        real * real + imaginary * imaginary
    }
    
    /// 複素共役
    /// a + bi の共役は a - bi
    public var conjugate: Complex {
        Complex(real: real, imaginary: -imaginary)
    }
    
    /// 偏角（位相）
    /// 複素平面上での角度（ラジアン）
    public var phase: Double {
        atan2(imaginary, real)
    }
}

// MARK: - 複素数の演算

extension Complex {
    /// 加算: (a + bi) + (c + di) = (a+c) + (b+d)i
    public static func + (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
    }
    
    /// 減算: (a + bi) - (c + di) = (a-c) + (b-d)i
    public static func - (lhs: Complex, rhs: Complex) -> Complex {
        Complex(real: lhs.real - rhs.real, imaginary: lhs.imaginary - rhs.imaginary)
    }
    
    /// 乗算: (a + bi)(c + di) = (ac - bd) + (ad + bc)i
    /// 展開して i² = -1 を適用
    public static func * (lhs: Complex, rhs: Complex) -> Complex {
        Complex(
            real: lhs.real * rhs.real - lhs.imaginary * rhs.imaginary,
            imaginary: lhs.real * rhs.imaginary + lhs.imaginary * rhs.real
        )
    }
    
    /// 実数倍
    public static func * (lhs: Double, rhs: Complex) -> Complex {
        Complex(real: lhs * rhs.real, imaginary: lhs * rhs.imaginary)
    }
    
    /// 実数倍（順序逆）
    public static func * (lhs: Complex, rhs: Double) -> Complex {
        Complex(real: lhs.real * rhs, imaginary: lhs.imaginary * rhs)
    }
}
