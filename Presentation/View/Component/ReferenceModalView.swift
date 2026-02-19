
import SwiftUI

struct ReferenceModalView: View {

    var onDismiss: () -> Void

    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .onTapGesture {
                    dismissModal()
                }

            VStack(spacing: 40) {
                Text("GATE REFERENCE")
                    .font(.system(size: 45, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 3)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        gateRow(gate: .x, name: "Pauli-X", description: "Bit Flip\n|0⟩ ↔ |1⟩")
                        gateRow(gate: .y, name: "Pauli-Y", description: "Bit & Phase Flip\n180° Y-Rot")
                        gateRow(gate: .z, name: "Pauli-Z", description: "Phase Flip\n|1⟩ → -|1⟩")
                        gateRow(gate: .h, name: "Hadamard", description: "Superposition\n|0⟩ → |+⟩")
                        gateRow(gate: .s, name: "Phase (S)", description: "90° Phase Shift\n√Z Gate")
                        gateRow(gate: .t, name: "T Gate", description: "45° Phase Shift\n√S Gate")
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 360)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismissModal()
                }) {
                    Text("CANCEL")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(.white.opacity(0.3), lineWidth: 3)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                .accessibilityLabel("Cancel")
                .accessibilityHint("Return to the game.")
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.5), .purple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .frame(maxWidth: 760)
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0.0)
            .padding(20)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Gate reference")
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }

    private func dismissModal() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    @ViewBuilder
    private func gateRow(gate: QuantumGate, name: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(gate.symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(gate.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: gate.swiftUIColor.opacity(0.5), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(height: 80)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name). \(description.voiceOverFriendlyReferenceText)")
        .accessibilityHint("Reference information.")
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()

        ReferenceModalView(onDismiss: {})
    }
}

private extension String {
    var voiceOverFriendlyReferenceText: String {
        self
            .replacingOccurrences(of: "|0⟩", with: "ket zero")
            .replacingOccurrences(of: "|1⟩", with: "ket one")
            .replacingOccurrences(of: "|+⟩", with: "ket plus")
            .replacingOccurrences(of: "↔", with: "to")
    }
}
