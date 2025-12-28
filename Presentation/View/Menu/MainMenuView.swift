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
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
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
                    .font(.custom("Optima-Bold", size: 48))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // メニューボタン
                VStack(spacing: 20) {
                    // ゲームプレイボタン
                    GlassButton(
                        title: "🎮 Game Play",
                        action: onPlayGame,
                        width: 280,
                        height: 64,
                        fontSize: 24
                    )
                    
                    // 過去の記録ボタン
                    GlassButton(
                        title: "📊 Records",
                        action: onShowRecords,
                        width: 280,
                        height: 64,
                        fontSize: 24
                    )
                    
                    // アプリの使い方ボタン
                    GlassButton(
                        title: "📖 How to Play",
                        action: onShowHelp,
                        width: 280,
                        height: 64,
                        fontSize: 24
                    )
                }
                
                Spacer()
                Spacer()
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
