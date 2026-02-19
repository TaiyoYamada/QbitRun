import SwiftUI

struct SwiftUIGatePaletteView: View {
    let gates: [QuantumGate] = [.x, .y, .z, .h, .s, .t]
    let onGateSelected: (QuantumGate) -> Void
    var highlightedGate: QuantumGate?
    var allDisabled: Bool

    @State private var bouncePhase: Int = 0
    @State private var bounceTimer: Timer?

    init(highlightedGate: QuantumGate? = nil, allDisabled: Bool = false, onGateSelected: @escaping (QuantumGate) -> Void) {
        self.highlightedGate = highlightedGate
        self.allDisabled = allDisabled
        self.onGateSelected = onGateSelected
    }

    private func bounceScale(for gate: QuantumGate) -> CGFloat {
        guard highlightedGate == gate else { return 1.0 }
        switch bouncePhase {
        case 1: return 1.18
        default: return 1.1
        }
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.7), lineWidth: 1)
                        )
                }
                .buttonStyle(GateButtonStyle())
                .scaleEffect(allDisabled ? 1.0 : bounceScale(for: gate))
                .opacity(allDisabled ? 0.4 : (highlightedGate == nil || highlightedGate == gate ? 1.0 : 0.4))
                .grayscale(allDisabled ? 1.0 : (highlightedGate == nil || highlightedGate == gate ? 0.0 : 1.0))
                .disabled(allDisabled || (highlightedGate != nil && highlightedGate != gate))
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: bouncePhase)
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
        .onChange(of: highlightedGate) { _, newValue in
            if newValue != nil {
                startBounceLoop()
            } else {
                stopBounceLoop()
            }
        }
        .onAppear {
            if highlightedGate != nil {
                startBounceLoop()
            }
        }
    }

    private func startBounceLoop() {
        stopBounceLoop()
        bouncePhase = 0

        let delays: [Double] = [0.0, 0.3, 0.3, 0.8]

        func runCycle() {
            var accumulated: Double = 0
            for (i, delay) in delays.enumerated() {
                accumulated += delay
                let phase = i < 3 ? i + 1 : 0
                DispatchQueue.main.asyncAfter(deadline: .now() + accumulated) { [self] in
                    if highlightedGate != nil {
                        bouncePhase = phase
                    }
                }
            }
            let totalDuration = delays.reduce(0, +)
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [self] in
                if highlightedGate != nil {
                    runCycle()
                }
            }
        }
        runCycle()
    }

    private func stopBounceLoop() {
        bouncePhase = 0
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
