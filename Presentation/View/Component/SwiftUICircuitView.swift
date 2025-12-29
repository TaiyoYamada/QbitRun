import SwiftUI

/// 回路ビュー（シンプル版）
struct SwiftUICircuitView: View {
    @Binding var gates: [QuantumGate]
    let maxSlots: Int = 5
    let onRun: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 初期状態ラベル
            Text("|0⟩")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
            
            // ワイヤーとスロット
            HStack(spacing: 0) {
                ForEach(0..<maxSlots, id: \.self) { index in
                    // ワイヤーセグメント
                    Rectangle()
                        .fill(.white.opacity(0.4))
                        .frame(width: 20, height: 3)
                    
                    // スロット
                    CircuitSlot(
                        gate: index < gates.count ? gates[index] : nil,
                        onRemove: {
                            if index < gates.count {
                                gates.remove(at: index)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    )
                    
                    // ワイヤーセグメント
                    Rectangle()
                        .fill(.white.opacity(0.4))
                        .frame(width: 20, height: 3)
                }
            }
            
            // Runボタン
            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                onRun()
            }) {
                Text("▶ Run")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 40)
                    .background(gates.isEmpty ? Color.gray : Color(red: 0.3, green: 0.7, blue: 0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(gates.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 回路スロット
struct CircuitSlot: View {
    let gate: QuantumGate?
    let onRemove: () -> Void
    
    var body: some View {
        if let gate = gate {
            // ゲートが配置されている（タップで削除）
            Text(gate.symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(gate.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onRemove()
                }
        } else {
            // 空のスロット
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.08))
                .frame(width: 50, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.2), lineWidth: 2)
                )
        }
    }
}
