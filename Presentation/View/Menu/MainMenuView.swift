import SwiftUI

/// メインメニュー画面（ゲームプレイ、記録、使い方）
struct MainMenuView: View {
    
    /// ゲーム開始時のコールバック
    let onPlayGame: () -> Void
    
    /// 記録画面へ遷移
    let onShowRecords: () -> Void
    
    /// 使い方画面へ遷移
    let onShowHelp: () -> Void
    
    /// タイトル画面へ戻る
    var onBackToTitle: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（純黒）
                Color.black.ignoresSafeArea()
                
                // 背景回路（ループアニメーション）
                QuantumCircuitRepresentable(size: geometry.size)
                    .ignoresSafeArea()
                    .opacity(0.8)
                
                VStack(spacing: 24) {
                    // 戻るボタン
                    HStack {
                        if let onBack = onBackToTitle {
                            GlassIconButton(title: "Title", icon: "chevron.left", action: onBack)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // タイトル
                    Text("Main Menu")
                        .font(.custom("Optima-Bold", size: 60))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // メニューボタン
                    VStack(spacing: 40) {
                        // ゲームプレイボタン
                        GlassButton(
                            title: "Game Play",
                            action: onPlayGame,
                            width: 300,
                            height: 80,
                            fontSize: 30
                        )
                        
                        // 過去の記録ボタン
                        GlassButton(
                            title: "Records",
                            action: onShowRecords,
                            width: 300,
                            height: 80,
                            fontSize: 30
                        )
                        
                        // アプリの使い方ボタン
                        GlassButton(
                            title: "How to Play",
                            action: onShowHelp,
                            width: 300,
                            height: 80,
                            fontSize: 30
                        )
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
        }
    }
}

#Preview("メインメニュー") {
    MainMenuView(
        onPlayGame: { print("Play") },
        onShowRecords: { print("Records") },
        onShowHelp: { print("Help") },
        onBackToTitle: { print("Back") }
    )
}
