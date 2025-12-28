// SPDX-License-Identifier: MIT
// Presentation/Menu/MenuView.swift
// メニュー画面（SwiftUI版）

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SwiftUI View
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// SwiftUIではViewは値型（struct）で、状態が変わると自動的に再描画される
// @State: ビュー内部の状態を管理
// .task { }: 非同期処理をビューのライフサイクルに紐付ける
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// メニュー画面
struct MenuView: View {
    
    /// ゲーム開始時のコールバック
    let onStartGame: () -> Void
    
    /// スコアリポジトリ
    let scoreRepository: ScoreRepository
    
    /// ハイスコア
    @State private var highScore: Int = 0
    
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
            
            VStack(spacing: 0) {
                Spacer()
                
                // タイトル
                Text("Quantum Gate")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                
                // サブタイトル
                Text("Master the Bloch Sphere")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 8)
                
                // スタートボタン
                Button(action: {
                    // 触覚フィードバック
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    onStartGame()
                }) {
                    Text("Start Game")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 56)
                        .background(Color(red: 0.4, green: 0.2, blue: 0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 48)
                
                // ハイスコア
                Text(highScore > 0 ? "High Score: \(highScore)" : "No scores yet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.top, 24)
                
                Spacer()
                
                // 説明テキスト
                Text("Drag quantum gates to transform |0⟩\ninto the target state within 60 seconds")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .task {
            // ハイスコアを非同期で読み込み
            highScore = await scoreRepository.highScore()
        }
    }
}

/// ボタンのスケールアニメーション
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - プレビュー

#Preview("メニュー画面") {
    MenuView(
        onStartGame: { print("Start tapped") },
        scoreRepository: ScoreRepository()
    )
}
