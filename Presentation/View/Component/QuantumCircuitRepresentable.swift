import SwiftUI
import UIKit

struct QuantumCircuitRepresentable: UIViewRepresentable {
    let size: CGSize
    let isAnimated: Bool
    
    init(size: CGSize, isAnimated: Bool = true) {
        self.size = size
        self.isAnimated = isAnimated
    }

    func makeUIView(context: Context) -> QuantumCircuitAnimationView {
        let view = QuantumCircuitAnimationView()
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: QuantumCircuitAnimationView, context: Context) {
        guard size.width > 0 && size.height > 0 else { return }
        guard !context.coordinator.hasStarted else { return }

        context.coordinator.hasStarted = true

        uiView.frame = CGRect(origin: .zero, size: size)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            uiView.startLoopingAnimation(duration: 60.0, opacity: 0.25, isAnimated: self.isAnimated)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var hasStarted = false
    }
}
