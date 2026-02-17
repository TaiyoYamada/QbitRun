import SwiftUI

struct SwiftUIGatePaletteView: View {
    let gates: [QuantumGate] = [.x, .y, .z, .h, .s, .t]
    let onGateSelected: (QuantumGate) -> Void
    var highlightedGate: QuantumGate?
    var allDisabled: Bool

    init(highlightedGate: QuantumGate? = nil, allDisabled: Bool = false, onGateSelected: @escaping (QuantumGate) -> Void) {
        self.highlightedGate = highlightedGate
        self.allDisabled = allDisabled
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

                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        )
                }
                .buttonStyle(GateButtonStyle())
                .scaleEffect(highlightedGate == gate ? 1.1 : 1.0)
                .opacity(allDisabled ? 0.4 : (highlightedGate == nil || highlightedGate == gate ? 1.0 : 0.4))
                .grayscale(allDisabled ? 1.0 : (highlightedGate == nil || highlightedGate == gate ? 0.0 : 1.0))
                .disabled(allDisabled || (highlightedGate != nil && highlightedGate != gate))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: highlightedGate)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: allDisabled)
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

struct GateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BoundsPreferenceKey: PreferenceKey {
    typealias Value = [QuantumGate: Anchor<CGRect>]
    static let defaultValue: Value = [:]

    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}
