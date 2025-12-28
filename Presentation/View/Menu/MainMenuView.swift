import SwiftUI

/// メインメニュー画面（ゲームプレイ、記録、使い方）
struct MainMenuView: View {
    
    /// ゲーム開始時のコールバック
    let onPlayGame: () -> Void
    
    /// 記録画面へ遷移
    let onShowRecords: () -> Void
    
    /// 使い方画面へ遷移
    let onShowHelp: () -> Void
    
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
                Spacer()
                
                // タイトル
                Text("Main Menu")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // ゲームプレイボタン
                MenuButton(
                    title: "🎮 Game Play",
                    color: Color(red: 0.4, green: 0.2, blue: 0.8),
                    action: onPlayGame
                )
                
                // 過去の記録ボタン
                MenuButton(
                    title: "📊 Records",
                    color: Color(red: 0.2, green: 0.5, blue: 0.8),
                    action: onShowRecords
                )
                
                // アプリの使い方ボタン
                MenuButton(
                    title: "📖 How to Play",
                    color: Color(red: 0.3, green: 0.6, blue: 0.4),
                    action: onShowHelp
                )
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

/// メニューボタンコンポーネント
struct MenuButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview("メインメニュー") {
    MainMenuView(
        onPlayGame: { print("Play") },
        onShowRecords: { print("Records") },
        onShowHelp: { print("Help") }
    )
}
