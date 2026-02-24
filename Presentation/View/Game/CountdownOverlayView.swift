import SwiftUI

struct CountdownOverlayView: View {

    enum Phase {
        case countdown
        case start
        case timeUp
    }

    let phase: Phase
    let value: Int
    let scale: CGFloat
    let opacity: Double

    private var displayText: String {
        switch phase {
        case .countdown:
            return "\(value)"
        case .start:
            return "START!"
        case .timeUp:
            return "TIME UP!"
        }
    }

    private var usesHighlightStyle: Bool {
        phase != .countdown
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()

            Text(displayText)
                .tracking(2)
                .font(.system(size: usesHighlightStyle ? 110 : 140,
                              weight: .bold,
                              design: .rounded))
                .foregroundStyle(
                    !usesHighlightStyle
                    ? AnyShapeStyle(.white)
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.65, green: 0.95, blue: 1.0),
                                Color(red: 0.35, green: 0.50, blue: 0.95),
                                Color(red: 0.45, green: 0.20, blue: 0.70)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                      )
                )
                .shadow(color: .white.opacity(0.5), radius: 30)
                .scaleEffect(scale)
                .opacity(opacity)
        }
    }
}
