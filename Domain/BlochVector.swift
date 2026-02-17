
import Foundation
import simd

public struct BlochVector: Sendable, Equatable {
    public let vector: simd_double3

    public init(x: Double, y: Double, z: Double) {
        let v = simd_double3(x, y, z)
        let length = simd_length(v)

        if length > 0 {
            self.vector = v / length
        } else {
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

    public init(from state: QuantumState) {
        let alpha = state.alpha
        let beta = state.beta

        let x = 2 * (alpha.real * beta.real + alpha.imaginary * beta.imaginary)

        let y = 2 * (alpha.real * beta.imaginary - alpha.imaginary * beta.real)

        let z = alpha.magnitudeSquared - beta.magnitudeSquared

        self.init(x: x, y: y, z: z)
    }

    public var x: Double { vector.x }
    public var y: Double { vector.y }
    public var z: Double { vector.z }

    public var float3: simd_float3 {
        simd_float3(Float(x), Float(y), Float(z))
    }

    public var theta: Double {
        acos(max(-1, min(1, z)))
    }

    public var phi: Double {
        atan2(y, x)
    }

    public func distance(to other: BlochVector) -> Double {
        simd_distance(vector, other.vector)
    }

    public static let zero = BlochVector(x: 0, y: 0, z: 1)

    public static let one = BlochVector(x: 0, y: 0, z: -1)

    public static let plus = BlochVector(x: 1, y: 0, z: 0)

    public static let minus = BlochVector(x: -1, y: 0, z: 0)

    public static let plusI = BlochVector(x: 0, y: 1, z: 0)

    public static let minusI = BlochVector(x: 0, y: -1, z: 0)
}
