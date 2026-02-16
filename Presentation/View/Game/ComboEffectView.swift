// SPDX-License-Identifier: MIT
// Presentation/View/Game/ComboEffectView.swift

import SwiftUI

/// コンボ発生時のエフェクトビュー
struct ComboEffectView: View {
    let comboCount: Int
    let bonus: Int
    
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible && comboCount >= 2 {
            VStack(spacing: 4) {
                Text("\(comboCount) COMBO!")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.8), radius: 10, x: 0, y: 0)
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                if bonus > 0 {
                    Text("+\(bonus) pts")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding()
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .blur(radius: 20)
            )
            .rotationEffect(.degrees(isVisible ? -5 : 5))
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isVisible)
        }
    }
}
