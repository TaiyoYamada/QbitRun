
import SwiftUI

struct TutorialConfirmationView: View {

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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onCancel()
                    }
                }

            VStack(spacing: 40) {

                Text("TUTORIAL")
                    .font(.system(size: 45, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 3)

                HStack(spacing: 25) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            animateIn = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
                    .accessibilityHint("Close without starting tutorial.")

                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        onConfirm()
                    }) {
                        Text("START")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.cyan.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(.white.opacity(0.6), lineWidth: 3)
                            )
                    }
                    .accessibilityLabel("Start tutorial")
                    .accessibilityHint("Begin tutorial review.")
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
                            colors: [.cyan.opacity(0.5), .purple.opacity(0.5)],
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
            .accessibilityLabel("Tutorial confirmation")
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
}
