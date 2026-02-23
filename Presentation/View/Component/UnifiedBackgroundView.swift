
import SwiftUI

struct UnifiedBackgroundView: View {

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.03, green: 0.05, blue: 0.25),
                    .black
                ],
                center: .center,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()



            QuantumCircuitRepresentable(size: CGSize(width: 1000, height: 1000))
                .ignoresSafeArea()
                .opacity(0.4)

                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.03, green: 0.05, blue: 0.18), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 200)
                        .allowsHitTesting(false)

                    Spacer()

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color(red: 0.03, green: 0.05, blue: 0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 200)
                        .allowsHitTesting(false)
                }
                .ignoresSafeArea()

        }
    }
}

#Preview {
    UnifiedBackgroundView()
}
