
import SwiftUI

struct UnifiedBackgroundView: View {

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            QuantumCircuitRepresentable(size: CGSize(width: 1000, height: 1000))
                .ignoresSafeArea()
                .opacity(0.4)

            VStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.18), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 300)
                    .allowsHitTesting(false)

                Spacer()

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.18), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 300)
                    .allowsHitTesting(false)
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    UnifiedBackgroundView()
}
