import SwiftUI
import UIKit

struct EffectOverlayView: UIViewRepresentable {
    @Binding var showSuccess: Bool
    @Binding var showFailure: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if showSuccess {
            CircuitAnimator.showQuantumSuccessEffect(on: uiView)
        }
        if showFailure {
            CircuitAnimator.showFailureEffect(on: uiView)
        }
    }
}
