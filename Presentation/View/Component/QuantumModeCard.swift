
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
                        .strokeBorder(
                            accentColor.opacity(0.8),
                            lineWidth: 2
                        )
                        .background(
                            Circle().fill(Color.black)
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: accentColor.opacity(isHovered ? 0.8 : 0.4), radius: 5)

                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(accentColor)
                        .shadow(color: accentColor.opacity(0.5), radius: 4)

                    Text(subtitle)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor.opacity(0.8))
            }
            .padding(24)
            .background(
                ZStack {
                    Color.black.opacity(0.9)

                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            accentColor.opacity(0.7),
                            lineWidth: 3
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .cyan.opacity(0.7), radius: 3)
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

#Preview {
    ZStack {
        Color.gray
        VStack {
            QuantumModeCard(
                title: "EASY MODE",
                subtitle: "Start from |0⟩",
                icon: "",
                accentColor: .cyan,
                isRandomStart: false,
                action: {}
            )

            QuantumModeCard(
                title: "HARD MODE",
                subtitle: "Random Start State",
                icon: "",
                accentColor: .orange,
                isRandomStart: true,
                action: {}
            )
        }
        .padding()
    }
}
