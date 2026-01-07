// SPDX-License-Identifier: MIT
// Presentation/View/Component/ParticleEffectRepresentable.swift
// パーティクルエフェクトのSwiftUIラッパー

import SwiftUI
import UIKit

/// パーティクル収束エフェクトを表示するUIViewRepresentable
struct ParticleEffectRepresentable: UIViewRepresentable {
    
    /// エフェクト発火用トリガー（UUIDが変更されると発火）
    @Binding var trigger: UUID?
    
    /// エフェクトのターゲット（収束）中心点
    var targetCenter: CGPoint
    
    /// エフェクト完了時のコールバック
    var onComplete: () -> Void
    
    func makeUIView(context: Context) -> ParticleConvergeEffectView {
        let view = ParticleConvergeEffectView()
        view.onConvergeComplete = {
            onComplete()
        }
        return view
    }
    
    func updateUIView(_ uiView: ParticleConvergeEffectView, context: Context) {
        // トリガーが新しくなった場合のみエフェクトを開始
        if let id = trigger, id != context.coordinator.lastTriggerId {
            context.coordinator.lastTriggerId = id
            
            // 少し遅延させて、レイアウト確定後にアニメーション開始
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
