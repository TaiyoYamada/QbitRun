
import SwiftUI
import UIKit

struct ExitConfirmationView: View {

    let title: String
    let message: String
    var confirmText: String = "EXIT GAME"
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateIn = false
                    }
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(200))
                        onCancel()
                    }
                }

            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 45, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.5), radius: 3)

                    Text(message)
                        .font(.system(size: 30, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack(spacing: 25) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            animateIn = false
                        }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(200))
                            onCancel()
                        }
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
                    .accessibilityLabel("Cancel")
                    .accessibilityHint("Continue current game.")

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        onConfirm()
                    }) {
                        Text(confirmText)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.9),
                                        Color(red: 0.24, green: 0.36, blue: 0.82),
                                        Color(red: 0.25, green: 0.08, blue: 0.48)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(.white.opacity(0.6), lineWidth: 3)
                            )
                    }
                    .accessibilityLabel(confirmText == "EXIT" ? "Exit review" : "Exit game")
                    .accessibilityHint("Return to the main menu.")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.9),
                                Color(red: 0.24, green: 0.36, blue: 0.82),
                                Color(red: 0.25, green: 0.08, blue: 0.48)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .frame(maxWidth: 520)
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0.0)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Exit confirmation")
        }
        .onAppear {
            announceForVoiceOver()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }

    private func announceForVoiceOver() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .screenChanged, argument: "Exit confirmation")
    }
}
