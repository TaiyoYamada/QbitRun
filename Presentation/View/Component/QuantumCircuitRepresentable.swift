// SPDX-License-Identifier: MIT
// Presentation/View/Component/QuantumCircuitRepresentable.swift

import SwiftUI
import UIKit

/// 量子回路のアニメーションを表示するViewRepresentable
/// タイトル画面やメニュー画面の背景として使用
struct QuantumCircuitRepresentable: UIViewRepresentable {
    let size: CGSize
    
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
            // ゆっくり（30秒）、薄く（0.25）ループ再生
            uiView.startLoopingAnimation(duration: 30.0, opacity: 0.25)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hasStarted = false
    }
}
