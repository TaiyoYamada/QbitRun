import Foundation

/// 量子回路を表す構造体
public struct Circuit: Sendable {
    /// 回路に含まれるゲートのリスト（適用順）
    public private(set) var gates: [QuantumGate]
    
    /// 回路に追加できる最大ゲート数
    public let maxGates: Int
    
    // MARK: - イニシャライザ
    
    /// 空の回路を作成
    /// - Parameter maxGates: 最大ゲート数（デフォルト6）
    public init(maxGates: Int = 6) {
        self.gates = []
        self.maxGates = maxGates
    }
    
    /// ゲートリストを指定して作成
    public init(gates: [QuantumGate], maxGates: Int = 6) {
        self.gates = Array(gates.prefix(maxGates))
        self.maxGates = maxGates
    }
    
    // MARK: - ゲート操作
    
    /// ゲートを追加
    /// - Returns: 追加に成功したかどうか
    @discardableResult
    public mutating func addGate(_ gate: QuantumGate) -> Bool {
        guard gates.count < maxGates else { return false }
        gates.append(gate)
        return true
    }
    
    /// 指定インデックスのゲートを削除
    public mutating func removeGate(at index: Int) {
        guard gates.indices.contains(index) else { return }
        gates.remove(at: index)
    }
    
    /// 最後のゲートを削除
    public mutating func removeLastGate() {
        gates.removeLast()
    }
    
    /// 全ゲートをクリア
    public mutating func clear() {
        gates.removeAll()
    }
    
    // MARK: - 状態変換
    
    /// 回路を量子状態に適用
    /// |ψ_out⟩ = G_n × G_(n-1) × ... × G_1 × |ψ_in⟩
    public func apply(to state: QuantumState) -> QuantumState {
        state.applying(gates)
    }
    
    /// 各ゲート適用後の中間状態を取得
    /// デバッグやアニメーション用
    public func intermediateStates(from initial: QuantumState) -> [QuantumState] {
        var states: [QuantumState] = [initial]
        var current = initial
        
        for gate in gates {
            current = gate.apply(to: current)
            states.append(current)
        }
        
        return states
    }
    
    // MARK: - 情報取得
    
    /// ゲート数
    public var gateCount: Int {
        gates.count
    }
    
    /// 回路が空かどうか
    public var isEmpty: Bool {
        gates.isEmpty
    }
    
    /// 回路が満杯かどうか
    public var isFull: Bool {
        gates.count >= maxGates
    }
}
