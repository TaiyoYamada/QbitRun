import Foundation
import simd

/// ブロッホ球上の単位ベクトル．量子状態を3次元空間上の点として視覚化するために使用
public struct BlochVector: Sendable, Equatable {
    public let vector: simd_double3

    // ブロッホ球上の点 → 単位ベクトルに正規化
    public init(x: Double, y: Double, z: Double) {
        let v = simd_double3(x, y, z)
        let length = simd_length(v)

        if length > 0 {
            // r̂ = v / |v|
            self.vector = v / length
        } else {
            // ゼロベクトル → 北極 (|0⟩) にフォールバック
            self.vector = simd_double3(0, 0, 1)
        }
    }

    public init(_ v: simd_double3) {
        let length = simd_length(v)
        if length > 0 {
            self.vector = v / length
        } else {
            self.vector = simd_double3(0, 0, 1)
        }
    }

    // |ψ⟩ = α|0⟩ + β|1⟩ → ブロッホベクトル (x, y, z)
    public init(from state: QuantumState) {
        let alpha = state.alpha
        let beta = state.beta

        // x = 2·Re(α*β) = ⟨ψ|σₓ|ψ⟩
        let x = 2 * (alpha.real * beta.real + alpha.imaginary * beta.imaginary)

        // y = 2·Im(α*β) = ⟨ψ|σᵧ|ψ⟩
        let y = 2 * (alpha.real * beta.imaginary - alpha.imaginary * beta.real)

        // z = |α|² - |β|² = ⟨ψ|σ_z|ψ⟩
        let z = alpha.magnitudeSquared - beta.magnitudeSquared

        self.init(x: x, y: y, z: z)
    }

    public var x: Double { vector.x }
    public var y: Double { vector.y }
    public var z: Double { vector.z }

    public var float3: simd_float3 {
        simd_float3(Float(x), Float(y), Float(z))
    }

    // 極角 θ = arccos(z) ∈ [0, π]
    public var theta: Double {
        acos(max(-1, min(1, z)))
    }

    // 方位角 φ = atan2(y, x) ∈ (-π, π]
    public var phi: Double {
        atan2(y, x)
    }

    public func distance(to other: BlochVector) -> Double {
        simd_distance(vector, other.vector)
    }

    // |0⟩ → 北極 (0, 0, 1)
    public static let zero = BlochVector(x: 0, y: 0, z: 1)

    // |1⟩ → 南極 (0, 0, -1)
    public static let one = BlochVector(x: 0, y: 0, z: -1)

    // |+⟩ → +X軸 (1, 0, 0)
    public static let plus = BlochVector(x: 1, y: 0, z: 0)

    // |−⟩ → -X軸 (-1, 0, 0)
    public static let minus = BlochVector(x: -1, y: 0, z: 0)

    // |+i⟩ → +Y軸 (0, 1, 0)
    public static let plusI = BlochVector(x: 0, y: 1, z: 0)

    // |−i⟩ → -Y軸 (0, -1, 0)
    public static let minusI = BlochVector(x: 0, y: -1, z: 0)
}
