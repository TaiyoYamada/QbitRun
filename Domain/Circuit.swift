import Foundation

/// 量子回路を表す値型
public struct Circuit: Sendable {
    public private(set) var gates: [QuantumGate]

    public let maxGates: Int

    public init(maxGates: Int = 6) {
        self.gates = []
        self.maxGates = maxGates
    }

    public init(gates: [QuantumGate], maxGates: Int = 6) {
        self.gates = Array(gates.prefix(maxGates))
        self.maxGates = maxGates
    }

    @discardableResult
    public mutating func addGate(_ gate: QuantumGate) -> Bool {
        guard gates.count < maxGates else { return false }
        gates.append(gate)
        return true
    }

    public mutating func removeGate(at index: Int) {
        guard gates.indices.contains(index) else { return }
        gates.remove(at: index)
    }

    public mutating func removeLastGate() {
        _ = gates.popLast()
    }

    public mutating func clear() {
        gates.removeAll()
    }

    public func apply(to state: QuantumState) -> QuantumState {
        state.applying(gates)
    }

    public func intermediateStates(from initial: QuantumState) -> [QuantumState] {
        var states: [QuantumState] = [initial]
        var current = initial

        for gate in gates {
            current = gate.apply(to: current)
            states.append(current)
        }

        return states
    }

    public var gateCount: Int {
        gates.count
    }

    public var isEmpty: Bool {
        gates.isEmpty
    }

    public var isFull: Bool {
        gates.count >= maxGates
    }
}
