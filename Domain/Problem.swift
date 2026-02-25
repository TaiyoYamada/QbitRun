import Foundation

/// 1問分の出題データ
public struct Problem: Sendable {
    public let startState: QuantumState

    public let startBlochVector: BlochVector

    public let targetState: QuantumState

    public let targetBlochVector: BlochVector

    public let minimumGates: Int

    public let referenceSolution: [QuantumGate]

    public let difficulty: Int
}
