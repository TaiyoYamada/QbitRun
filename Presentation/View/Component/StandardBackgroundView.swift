import SwiftUI

struct StandardBackgroundView: View {

    var showGrid: Bool = true

    var circuitOpacity: Double = 0.3

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            QuantumCircuitRepresentable(
                size: CGSize(width: 1000, height: 1000)
            )
            .ignoresSafeArea()
            .opacity(circuitOpacity)
            .drawingGroup()

            if showGrid {
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan.opacity(0.05), .clear],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: 300)
                }
                .ignoresSafeArea()
            }

            RadialGradient(
                colors: [.clear, .black.opacity(0.6)],
                center: .center,
                startRadius: 400,
                endRadius: 900
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}

#Preview("背景", traits: .landscapeLeft) {
    StandardBackgroundView()
}
