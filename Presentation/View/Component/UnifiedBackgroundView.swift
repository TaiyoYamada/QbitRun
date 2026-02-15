// SPDX-License-Identifier: MIT
// Presentation/View/Component/UnifiedBackgroundView.swift

import SwiftUI

/// ゲーム全体で統一された背景ビュー
/// 黒背景 + 量子回路オーバーレイ（不透明度0.4） + 上下のシアン系グラデーションブラー
struct UnifiedBackgroundView: View {
    
    var body: some View {
        ZStack {
            // Didactic Black Background
            Color.black.ignoresSafeArea()

            // Quantum Circuit Overlay
            // Assuming QuantumCircuitRepresentable is available and fits any size
            QuantumCircuitRepresentable(size: CGSize(width: 1000, height: 1000))
                .ignoresSafeArea()
                .opacity(0.4)

            // Top and Bottom Blurs
            VStack {
                // Top Blur (Cyan to Transparent)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.18), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 300)
                    .allowsHitTesting(false) // Pass touches through

                Spacer()
                
                // Bottom Blur (Transparent to Cyan)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.18), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 300)
                    .allowsHitTesting(false) // Pass touches through
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    UnifiedBackgroundView()
}
