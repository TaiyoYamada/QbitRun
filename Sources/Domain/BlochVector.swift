// SPDX-License-Identifier: MIT
// Domain/BlochVector.swift
// ブロッホ球上の3Dベクトル表現

import Foundation
import simd

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ブロッホ球とは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 1量子ビットの純粋状態は、単位球面（ブロッホ球）上の
// 1点として可視化できる。
//
//                 |0⟩ (北極)
//                   ↑
//                   |
//       |−⟩ ←──────●──────→ |+⟩  (X軸)
//                  /|
//                 / |
//               |i⟩ (Y軸)
//                   |
//                   ↓
//                 |1⟩ (南極)
//
// 量子状態 |ψ⟩ = cos(θ/2)|0⟩ + e^(iφ)sin(θ/2)|1⟩
//
// ブロッホベクトル座標:
//   x = sin(θ)cos(φ)
//   y = sin(θ)sin(φ)
//   z = cos(θ)
//
// 重要な対応:
//   |0⟩ → (0, 0, +1) 北極
//   |1⟩ → (0, 0, -1) 南極
//   |+⟩ → (+1, 0, 0) X軸正
//   |-⟩ → (-1, 0, 0) X軸負
//   |i⟩ → (0, +1, 0) Y軸正
//  |-i⟩ → (0, -1, 0) Y軸負
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// ブロッホ球上の単位3Dベクトル
/// 量子状態を可視化するために使用
public struct BlochVector: Sendable, Equatable {
    /// 内部の3Dベクトル（simd_double3）
    /// simd: SIMD（Single Instruction Multiple Data）最適化された数学ライブラリ
    public let vector: simd_double3
    
    // MARK: - イニシャライザ
    
    /// x, y, z座標から作成（自動正規化）
    public init(x: Double, y: Double, z: Double) {
        let v = simd_double3(x, y, z)
        let length = simd_length(v)
        
        // 長さが0でなければ正規化して単位ベクトルに
        if length > 0 {
            self.vector = v / length
        } else {
            // 零ベクトルの場合は北極（|0⟩）に
            self.vector = simd_double3(0, 0, 1)
        }
    }
    
    /// simd_double3から作成（自動正規化）
    public init(_ v: simd_double3) {
        let length = simd_length(v)
        if length > 0 {
            self.vector = v / length
        } else {
            self.vector = simd_double3(0, 0, 1)
        }
    }
    
    /// 量子状態からブロッホベクトルへ変換
    /// これが最も重要な変換関数
    public init(from state: QuantumState) {
        // ブロッホベクトルの各成分を計算
        // 公式:
        //   x = 2 * Re(α*β)  = 2 * (αr*βr + αi*βi)
        //   y = 2 * Im(α*β)  = 2 * (αr*βi - αi*βr)
        //   z = |α|² - |β|²
        
        let alpha = state.alpha
        let beta = state.beta
        
        // x成分: α*β の実部 × 2
        let x = 2 * (alpha.real * beta.real + alpha.imaginary * beta.imaginary)
        
        // y成分: α*β の虚部 × 2（符号に注意）
        let y = 2 * (alpha.real * beta.imaginary - alpha.imaginary * beta.real)
        
        // z成分: |α|² - |β|²
        let z = alpha.magnitudeSquared - beta.magnitudeSquared
        
        self.init(x: x, y: y, z: z)
    }
    
    // MARK: - 座標アクセサ
    
    public var x: Double { vector.x }
    public var y: Double { vector.y }
    public var z: Double { vector.z }
    
    /// Float版のベクトル（Metal描画用）
    public var float3: simd_float3 {
        simd_float3(Float(x), Float(y), Float(z))
    }
    
    // MARK: - 球面座標
    
    /// 極角θ（theta）: 北極からの角度 [0, π]
    /// θ = 0 → 北極（|0⟩）
    /// θ = π → 南極（|1⟩）
    /// θ = π/2 → 赤道（|+⟩, |-⟩ など）
    public var theta: Double {
        acos(max(-1, min(1, z)))
    }
    
    /// 方位角φ（phi）: XY平面上の角度 [0, 2π]
    /// φ = 0 → |+⟩ 方向
    /// φ = π/2 → |i⟩ 方向
    public var phi: Double {
        atan2(y, x)
    }
    
    // MARK: - 距離計算
    
    /// 2つのブロッホベクトル間のユークリッド距離
    /// - 距離 0: 同じ状態
    /// - 距離 2: 反対側（直交状態ではない！）
    ///
    /// 注: ゲームでは「どれくらい近いか」の視覚的フィードバックに使用
    public func distance(to other: BlochVector) -> Double {
        simd_distance(vector, other.vector)
    }
    
    // MARK: - 特殊なベクトル（基底状態に対応）
    
    /// |0⟩ に対応（北極）
    public static let zero = BlochVector(x: 0, y: 0, z: 1)
    
    /// |1⟩ に対応（南極）
    public static let one = BlochVector(x: 0, y: 0, z: -1)
    
    /// |+⟩ に対応（X軸正方向）
    public static let plus = BlochVector(x: 1, y: 0, z: 0)
    
    /// |-⟩ に対応（X軸負方向）
    public static let minus = BlochVector(x: -1, y: 0, z: 0)
    
    /// |i⟩ に対応（Y軸正方向）
    public static let plusI = BlochVector(x: 0, y: 1, z: 0)
    
    /// |-i⟩ に対応（Y軸負方向）
    public static let minusI = BlochVector(x: 0, y: -1, z: 0)
}
