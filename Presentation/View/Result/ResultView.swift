// SPDX-License-Identifier: MIT
// Presentation/View/Result/ResultView.swift
// ゲーム終了画面（SwiftUI版）

import SwiftUI

/// ゲーム終了後のリザルト画面
struct ResultView: View {
    
    /// ViewModel
    @State private var viewModel: ResultViewModel
    
    /// もう一度プレイ
    let onPlayAgain: () -> Void
    
    /// メニューに戻る
    let onReturnToMenu: () -> Void
    
    // MARK: - 初期化
    
    init(score: ScoreEntry, scoreRepository: ScoreRepository, onPlayAgain: @escaping () -> Void, onReturnToMenu: @escaping () -> Void) {
        self._viewModel = State(initialValue: ResultViewModel(score: score, scoreRepository: scoreRepository))
        self.onPlayAgain = onPlayAgain
        self.onReturnToMenu = onReturnToMenu
    }
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // Time's Up!
                Text("Time's Up!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                
                // スコア（大きな数字）
                Text("\(viewModel.score.score)")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                    .padding(.top, 16)
                
                // 統計情報
                Text("Problems Solved: \(viewModel.score.problemsSolved)\nBonus Points: \(viewModel.score.bonusPoints)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                
                // ランキング順位
                if let rank = viewModel.rank {
                    Text("🏆 Rank #\(rank)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.8, blue: 0.2))
                        .padding(.top, 16)
                }
                
                // Play Againボタン
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onPlayAgain()
                }) {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 180, height: 50)
                        .background(Color(red: 0.4, green: 0.2, blue: 0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 32)
                
                // Menuボタン
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    onReturnToMenu()
                }) {
                    Text("Menu")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 180, height: 50)
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 12)
                
                Spacer()
            }
        }
        .task {
            await viewModel.loadResults()
        }
    }
}

// MARK: - プレビュー

#Preview("リザルト画面") {
    ResultView(
        score: ScoreEntry(score: 1500, problemsSolved: 8, bonusPoints: 300),
        scoreRepository: ScoreRepository(),
        onPlayAgain: { },
        onReturnToMenu: { }
    )
}
