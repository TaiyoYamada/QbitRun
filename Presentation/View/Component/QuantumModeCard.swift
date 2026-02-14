
import SwiftUI

/// A "Solid Tech" style button for mode selection
struct QuantumModeCard: View {
    let title: String
    let subtitle: String
    let icon: String // SystemImage name
    let accentColor: Color
    let isRandomStart: Bool // To toggle between Fixed/Random visualization
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
                // Icon / Visualizer Area
                ZStack {
                    // Tech Circle Background
                    Circle()
                        .strokeBorder(
                            accentColor.opacity(0.8),
                            lineWidth: 2
                        )
                        .background(
                            Circle().fill(Color.black)
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: accentColor.opacity(isHovered ? 0.8 : 0.4), radius: 10)
                    
                    // Central Icon
                    if isRandomStart {
                        // Hard Mode: Random / Chaos
                        Image(systemName: "questionmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(accentColor)
                            .symbolEffect(.pulse, options: .repeating)
                    } else {
                        // Easy Mode: Fixed |0>
                        Image(systemName: "arrow.up")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(accentColor)
                    }
                }
                
                // Text Area
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(accentColor)
                        .shadow(color: accentColor.opacity(0.5), radius: 4)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Tech Decor
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(accentColor.opacity(0.6))
            }
            .padding(24)
            .background(
                ZStack {
                    // Solid Matte Black Background
                    Color.black.opacity(0.9)
                    
                    // Tech Border
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [accentColor, accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
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
