
import SwiftUI

struct ComboEffectView: View {
    let comboCount: Int
    let bonus: Int

    @Binding var isVisible: Bool

    var body: some View {
        if comboCount >= 2 {
            VStack(spacing: 4) {
                let comboColors: [Color] = {
                    if comboCount < 5 {
                        return [.purple.opacity(0.8), .purple]
                    } else if comboCount < 10 {
                        return [.white, .cyan, .blue]
                    } else {
                        return [.purple, .blue, .cyan, .white]
                    }
                }()

                Text("\(comboCount) COMBO")
                    .font(.system(size: 45, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: comboColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: comboColors.last?.opacity(0.8) ?? .orange.opacity(0.8), radius: 5, x: 0, y: 0)
                    .scaleEffect(isVisible ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isVisible)

                if isVisible && bonus > 0 {
                    Text("+\(bonus) pts")
                        .font(.system(size: 35, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
            .background(
                Circle()
                .fill(.ultraThinMaterial)
                .blur(radius: 20)
                .opacity(0.5)
            )
            .rotationEffect(.degrees(isVisible ? -5 : 5))
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isVisible)
        }
    }
}
