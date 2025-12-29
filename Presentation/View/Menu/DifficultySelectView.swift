// SPDX-License-Identifier: MIT
// Presentation/View/Menu/DifficultySelectView.swift
// 難易度選択画面

import SwiftUI

/// 難易度選択画面
struct DifficultySelectView: View {
    
    /// 難易度選択時のコールバック
    let onSelectDifficulty: (GameDifficulty) -> Void
    
    /// 戻るボタンのコールバック
    let onBack: () -> Void
    
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
                    GlassIconButton(title: "Back", icon: "chevron.left", action: onBack)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // タイトル
                Text("Select Difficulty")
                    .font(.custom("Optima-Bold", size: 40))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // 難易度ボタン
                VStack(spacing: 24) {
                    // Easy
                    DifficultyButton(
                        difficulty: .easy,
                        action: { onSelectDifficulty(.easy) }
                    )
                    
                    // Hard
                    DifficultyButton(
                        difficulty: .hard,
                        action: { onSelectDifficulty(.hard) }
                    )
                }
                
                Spacer()
                Spacer()
            }
        }
    }
}

/// 難易度ボタン
private struct DifficultyButton: View {
    let difficulty: GameDifficulty
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Text(difficulty.emoji)
                        .font(.system(size: 32))
                    Text(difficulty.displayName)
                        .font(.custom("Optima-Bold", size: 28))
                        .foregroundStyle(.white)
                }
                
                Text(difficulty.description)
                    .font(.custom("Optima", size: 16))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(width: 280, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                difficulty == .hard
                                    ? Color.orange.opacity(0.5)
                                    : Color.white.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("難易度選択") {
    DifficultySelectView(
        onSelectDifficulty: { print("Selected: \($0)") },
        onBack: { print("Back") }
    )
}
