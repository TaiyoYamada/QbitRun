// SPDX-License-Identifier: MIT
// Domain/QuantumState.swift
// 量子状態を表す純粋なドメインモデル

import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 量子ビットとは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 古典ビット: 0 または 1 のどちらか一方
// 量子ビット: |0⟩ と |1⟩ の「重ね合わせ」状態が可能
//
// 量子状態は次の形で表される:
//   |ψ⟩ = α|0⟩ + β|1⟩
//
// ここで:
//   α, β = 複素数（Complex）の確率振幅
//   |α|² + |β|² = 1（正規化条件）
//   |α|² = |0⟩ を観測する確率
//   |β|² = |1⟩ を観測する確率
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - 複素数

/// 複素数を表す構造体
/// 量子力学では確率振幅が複素数なので必須
///
/// 複素数: a + bi の形（i は虚数単位、i² = -1）
/// 例: 3 + 4i → real = 3, imaginary = 4
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

// MARK: - 量子状態

/// 1量子ビットの量子状態を表す
/// |ψ⟩ = α|0⟩ + β|1⟩
///
/// この構造体は以下を保証する:
/// - 常に正規化されている（|α|² + |β|² = 1）
/// - Sendable準拠でスレッドセーフ
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
    
    // MARK: - 確率計算
    
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
    /// - 1.0: 完全一致（同じ状態）
    /// - 0.0: 直交（まったく異なる状態）
    ///
    /// ゲームでは「ターゲット状態にどれだけ近いか」を判定するのに使用
    public func fidelity(with other: QuantumState) -> Double {
        innerProduct(with: other).magnitudeSquared
    }
    
    // MARK: - ゲート適用
    
    /// 量子ゲートの配列を順番に適用
    public func applying(_ gates: [QuantumGate]) -> QuantumState {
        gates.reduce(self) { state, gate in gate.apply(to: state) }
    }
}
