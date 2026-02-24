import SwiftUI
import UIKit

struct GameCircuitSection: View {
    @Binding var circuitGates: [QuantumGate]
    let maxGates: Int
    let showCountdown: Bool
    let audioManager: AudioManager
    let onClear: () -> Void
    let onRun: () -> Void
    let onGateRemove: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    audioManager.playSFX(.clear)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onClear()
                    }
                }) {
                    Text("CLEAR")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.6), lineWidth: 5)
                        )
                }
                .accessibilityLabel("Clear circuit")
                .accessibilityHint("Remove all gates from the current circuit.")

                Spacer()
            }
            .padding(.leading, 73)
            .padding(.bottom, 15)

            SwiftUICircuitView(
                gates: $circuitGates,
                maxSlots: maxGates,
                onRun: { onRun() },
                onGateRemove: { index in
                    audioManager.playSFX(.clear)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onGateRemove(index)
                }
            )
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 0)
        }
        .opacity(showCountdown ? 0.5 : 1)
        .disabled(showCountdown)
    }
}
