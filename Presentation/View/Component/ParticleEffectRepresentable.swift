import SwiftUI
import UIKit

struct ParticleEffectRepresentable: UIViewRepresentable {

    @Binding var trigger: UUID?

    var targetCenter: CGPoint

    var onComplete: () -> Void

    func makeUIView(context: Context) -> ParticleConvergeEffectView {
        let view = ParticleConvergeEffectView()
        view.onConvergeComplete = {
            onComplete()
        }
        return view
    }

    func updateUIView(_ uiView: ParticleConvergeEffectView, context: Context) {
        if let id = trigger, id != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = id

            DispatchQueue.main.async {
                uiView.startEffectFromRightEdge(targetCenter: targetCenter)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var lastTriggerId: UUID?
    }
}
