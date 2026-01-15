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
                        .font(.custom("Optima-Bold", size: 28))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            ZStack {
                                gate.swiftUIColor
                                
                                // Internal gradient/shine for gem-like effect
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        )
                        .clipShape(Circle())
                        .shadow(color: gate.swiftUIColor.opacity(0.6), radius: 8, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(GateButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
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
