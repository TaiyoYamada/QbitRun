// SPDX-License-Identifier: MIT
// Domain/QuantumGate.swift
// 量子ゲート（1量子ビット操作）

import Foundation

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 量子ゲートとは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 古典コンピュータ: AND, OR, NOT などの論理ゲート
// 量子コンピュータ: ユニタリ行列で表される量子ゲート
//
// ユニタリ行列の条件: U†U = I（U†はエルミート共役）
// これにより量子操作は「可逆」かつ「確率を保存」する
//
// 1量子ビットゲートは 2×2 のユニタリ行列で表される:
//
//   |ψ'⟩ = U|ψ⟩
//
//   [α']   [u00  u01] [α]
//   [β'] = [u10  u11] [β]
//
// 主要なゲート:
//   X（NOT）: ビット反転 |0⟩ ↔ |1⟩
//   Z: 位相反転 |1⟩ → -|1⟩
//   H: 重ね合わせ作成 |0⟩ → |+⟩
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 1量子ビットに作用する量子ゲート
/// 各ゲートは2×2のユニタリ行列で表現される
public enum QuantumGate: String, CaseIterable, Sendable {
    case x  // パウリX（NOT）ゲート
    case y  // パウリYゲート
    case z  // パウリZゲート
    case h  // アダマールゲート
    case s  // 位相ゲート（π/2回転）
    case t  // π/8ゲート（π/4回転）
    
    // MARK: - ゲート行列
    
    /// ゲートの2×2ユニタリ行列を返す
    /// [[u00, u01], [u10, u11]]
    public var matrix: [[Complex]] {
        switch self {
        // ━━━━━━━━━━━━━━━━━━━
        // パウリXゲート（NOT）
        // ━━━━━━━━━━━━━━━━━━━
        // [0 1]
        // [1 0]
        //
        // |0⟩ → |1⟩
        // |1⟩ → |0⟩
        // ブロッホ球上: X軸周りに180°回転
        case .x:
            return [
                [.zero, .one],
                [.one, .zero]
            ]
            
        // ━━━━━━━━━━━━━━━━━━━
        // パウリYゲート
        // ━━━━━━━━━━━━━━━━━━━
        // [0  -i]
        // [i   0]
        //
        // ブロッホ球上: Y軸周りに180°回転
        case .y:
            return [
                [.zero, Complex(real: 0, imaginary: -1)],
                [.i, .zero]
            ]
            
        // ━━━━━━━━━━━━━━━━━━━
        // パウリZゲート
        // ━━━━━━━━━━━━━━━━━━━
        // [1  0]
        // [0 -1]
        //
        // |0⟩ → |0⟩
        // |1⟩ → -|1⟩（位相反転）
        // ブロッホ球上: Z軸周りに180°回転
        case .z:
            return [
                [.one, .zero],
                [.zero, Complex(real: -1, imaginary: 0)]
            ]
            
        // ━━━━━━━━━━━━━━━━━━━
        // アダマールゲート
        // ━━━━━━━━━━━━━━━━━━━
        // 1/√2 [1  1]
        //      [1 -1]
        //
        // |0⟩ → (|0⟩ + |1⟩)/√2 = |+⟩
        // |1⟩ → (|0⟩ - |1⟩)/√2 = |-⟩
        // 重ね合わせ状態を作る最も基本的なゲート
        case .h:
            let factor = 1.0 / 2.0.squareRoot()
            return [
                [Complex(real: factor, imaginary: 0), Complex(real: factor, imaginary: 0)],
                [Complex(real: factor, imaginary: 0), Complex(real: -factor, imaginary: 0)]
            ]
            
        // ━━━━━━━━━━━━━━━━━━━
        // Sゲート（位相ゲート）
        // ━━━━━━━━━━━━━━━━━━━
        // [1 0]
        // [0 i]
        //
        // |0⟩ → |0⟩
        // |1⟩ → i|1⟩（π/2位相シフト）
        // S² = Z
        case .s:
            return [
                [.one, .zero],
                [.zero, .i]
            ]
            
        // ━━━━━━━━━━━━━━━━━━━
        // Tゲート（π/8ゲート）
        // ━━━━━━━━━━━━━━━━━━━
        // [1       0    ]
        // [0  e^(iπ/4)  ]
        //
        // |0⟩ → |0⟩
        // |1⟩ → e^(iπ/4)|1⟩（π/4位相シフト）
        // T² = S, T⁸ = I
        case .t:
            let angle = Double.pi / 4
            let phase = Complex(real: cos(angle), imaginary: sin(angle))
            return [
                [.one, .zero],
                [.zero, phase]
            ]
        }
    }
    
    // MARK: - ゲート適用
    
    /// 量子状態にゲートを適用する
    /// |ψ'⟩ = U|ψ⟩ を計算
    public func apply(to state: QuantumState) -> QuantumState {
        let m = matrix
        
        // 行列とベクトルの積を計算
        // [α']   [m00  m01] [α]   [m00*α + m01*β]
        // [β'] = [m10  m11] [β] = [m10*α + m11*β]
        let newAlpha = m[0][0] * state.alpha + m[0][1] * state.beta
        let newBeta = m[1][0] * state.alpha + m[1][1] * state.beta
        
        return QuantumState(alpha: newAlpha, beta: newBeta)
    }
    
    // MARK: - ゲート情報
    
    /// ゲートの名前（フルネーム）
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
    
    /// ゲートの説明
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
