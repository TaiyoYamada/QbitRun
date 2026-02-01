import SwiftUI

/// アプリ全体で共通して使用する標準背景
/// MainMenuの世界観（黒背景＋量子回路アニメーション＋微細なグリッド）を統一して提供する
struct StandardBackgroundView: View {
    
    /// グリッドを表示するかどうか
    var showGrid: Bool = true
    
    /// 回路アニメーションの不透明度
    var circuitOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Layer 1: Deep Black
            Color.black.ignoresSafeArea()
            
            // Layer 2: Quantum Circuit Animation
            QuantumCircuitRepresentable(
                size: CGSize(width: 1000, height: 1000)
            )
            .ignoresSafeArea()
            .opacity(circuitOpacity)
            .drawingGroup() // パフォーマンス最適化
            
            // Layer 3: Cyber Grid (Optional)
            // 下部にうっすらと広がるグリッドで奥行きを表現
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
            
            // Layer 4: Subtle Vignette (Corner darkening)
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
