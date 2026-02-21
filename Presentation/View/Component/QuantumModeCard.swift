
import SwiftUI

struct QuantumModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let isRandomStart: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var iconBackgroundPhase = Double.random(in: 0...(2 * .pi))
    @State private var iconBackgroundSpeed = 1.0

    var body: some View {
        Button(action: {
            isPressed = true
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            Task {
                try? await Task.sleep(for: .milliseconds(150))
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.2))

                    Circle()
                        .strokeBorder(
                            accentColor.opacity(0.8),
                            lineWidth: 3
                        )

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .symbolEffect(.pulse, options: .repeating)
                }
                .frame(width: 60, height: 60)
                .shadow(color: accentColor.opacity(isHovered ? 0.8 : 0.4), radius: 5)

                VStack(alignment: .leading, spacing: 4) {
                    ZStack {
                        Text(title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(accentColor)
                            .shadow(color: accentColor.opacity(0.9), radius: 10)

                        Text(title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))


                    }
                    Text(subtitle)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor.opacity(0.9))
            }
            .padding(24)
            .background(
                ZStack {
                    Color.black.opacity(0.9)

                    RoundedRectangle(cornerRadius: 23)
                        .strokeBorder(
                            accentColor.opacity(0.7),
                            lineWidth: 3
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 23))
            .shadow(color: accentColor.opacity(0.6), radius: 8)
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
        .accessibilityHint("Double tap to start this mode.")
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
