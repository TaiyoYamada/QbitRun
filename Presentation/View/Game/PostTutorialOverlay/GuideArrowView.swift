import SwiftUI

struct GuideArrowView: View {
    let layout: PostTutorialGuideTargetLayout

    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "arrowshape.up.fill")
            .font(.system(size: 74, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .white,
                        Color(red: 0.65, green: 0.95, blue: 1.0),
                        Color(red: 0.35, green: 0.50, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .white.opacity(0.45), radius: 10)
            .rotationEffect(layout.arrowRotation)
            .offset(
                x: isAnimating ? 0 : -layout.arrowTravel.width,
                y: isAnimating ? 0 : -layout.arrowTravel.height
            )
            .opacity(isAnimating ? 1 : 0)
            .onAppear {
                isAnimating = false
                withAnimation(.easeOut(duration: 0.95).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            .accessibilityHidden(true)
    }
}
