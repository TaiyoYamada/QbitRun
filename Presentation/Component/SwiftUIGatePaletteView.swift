import SwiftUI

/// ゲートパレット（タップで追加）
struct SwiftUIGatePaletteView: View {
    let gates: [QuantumGate] = [.x, .y, .z, .h, .s, .t]
    let onGateSelected: (QuantumGate) -> Void
    
    init(onGateSelected: @escaping (QuantumGate) -> Void) {
        self.onGateSelected = onGateSelected
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(gates, id: \.self) { gate in
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onGateSelected(gate)
                } label: {
                    Text(gate.symbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(gate.swiftUIColor)
                        .clipShape(Circle())
                }
                .buttonStyle(GateButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// ボタンのスタイル
struct GateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - SwiftUI Color Extension

extension QuantumGate {
    var symbol: String {
        switch self {
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .h: return "H"
        case .s: return "S"
        case .t: return "T"
        }
    }
    
    var swiftUIColor: Color {
        switch self {
        case .x: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .y: return Color(red: 0.3, green: 0.8, blue: 0.3)
        case .z: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .h: return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .s: return Color(red: 0.7, green: 0.3, blue: 0.8)
        case .t: return Color(red: 0.2, green: 0.7, blue: 0.7)
        }
    }
}
