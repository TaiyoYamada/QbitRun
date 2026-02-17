import SwiftUI

/// ゲートパレット（タップで追加）
struct SwiftUIGatePaletteView: View {
    let gates: [QuantumGate] = [.x, .y, .z, .h, .s, .t]
    let onGateSelected: (QuantumGate) -> Void
    var highlightedGate: QuantumGate?
    
    init(highlightedGate: QuantumGate? = nil, onGateSelected: @escaping (QuantumGate) -> Void) {
        self.highlightedGate = highlightedGate
        self.onGateSelected = onGateSelected
    }
    
    var body: some View {
        HStack(spacing: 30) {
            ForEach(gates, id: \.self) { gate in
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onGateSelected(gate)
                } label: {
                    Text(gate.symbol)
                        .font(.system(size: 35, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 67, height: 67)
                        .background(
                            ZStack {
                                gate.swiftUIColor
                                
                                // Internal gradient/shine for gem-like effect
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        )
                        .clipShape(Circle())
//                        .shadow(color: gate.swiftUIColor.opacity(0.7), radius: 3, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        )
                }
                .buttonStyle(GateButtonStyle())
                .scaleEffect(highlightedGate == gate ? 1.1 : 1.0)
                .opacity(highlightedGate == nil || highlightedGate == gate ? 1.0 : 0.4) // Dim others
                .grayscale(highlightedGate == nil || highlightedGate == gate ? 0.0 : 1.0) // Grayscale others
                .disabled(highlightedGate != nil && highlightedGate != gate) // Disable interaction
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: highlightedGate)
                .anchorPreference(key: BoundsPreferenceKey.self, value: .bounds) { anchor in
                    [gate: anchor]
                }
            }
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 16)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 80))
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

/// Preference Key to collect UI bounds
struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = [QuantumGate: Anchor<CGRect>]
    static let defaultValue: Value = [:]
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}
