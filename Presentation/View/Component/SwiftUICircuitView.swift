import SwiftUI

struct SwiftUICircuitView: View {
    @Binding var gates: [QuantumGate]
    let maxSlots: Int
    let onRun: () -> Void
    let onGateRemove: (Int) -> Void

    private var wireWidth: CGFloat {
        maxSlots >= 6 ? 14 : 25
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("|0⟩")
                .font(.system(size: 30, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .accessibilityLabel("Input state, ket zero")

            HStack(spacing: 0) {
                ForEach(0..<maxSlots, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(width: wireWidth, height: 3)

                    CircuitSlot(
                        gate: index < gates.count ? gates[index] : nil,
                        onRemove: {
                            if index < gates.count {
                                onGateRemove(index)
                            }
                        }
                    )

                    Rectangle()
                        .fill(.white.opacity(0.7))
                        .frame(width: wireWidth, height: 3)
                }
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                onRun()
            }) {
                Text("▶ Run")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 3)
                    .frame(width: 120, height: 60)
                    .background {
                        if gates.isEmpty {
                            Color.gray
                        } else {
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(gates.isEmpty)
            .accessibilityLabel("Run circuit")
            .accessibilityValue(gates.isEmpty ? "Disabled" : "Enabled")
            .accessibilityHint(gates.isEmpty ? "Add at least one gate before running." : "Execute current circuit.")
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct CircuitSlot: View {
    let gate: QuantumGate?
    let onRemove: () -> Void

    var body: some View {
        if let gate = gate {
            Button {
                onRemove()
            } label: {
                Text(gate.symbol)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(gate.swiftUIColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(gate.circuitAccessibilityName) gate")
            .accessibilityHint("Double tap to remove this gate from the circuit.")
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.08))
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.2), lineWidth: 2)
                )
                .accessibilityHidden(true)
        }
    }
}

private extension QuantumGate {
    var circuitAccessibilityName: String {
        switch self {
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .h: return "H"
        case .s: return "S"
        case .t: return "T"
        }
    }
}
