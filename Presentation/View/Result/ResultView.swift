// SPDX-License-Identifier: MIT
// Presentation/Result/ResultView.swift
// ゲーム終了画面（SwiftUI版）

import SwiftUI

/// ゲーム終了後のリザルト画面
struct ResultView: View {
    
    /// 今回のスコア
    let score: ScoreEntry
    
    /// スコアリポジトリ
    let scoreRepository: ScoreRepository
    
    /// もう一度プレイ
    let onPlayAgain: () -> Void
    
    /// メニューに戻る
    let onReturnToMenu: () -> Void
    
    /// ランキング順位
    @State private var rank: Int?
    
    /// トップスコア一覧
    @State private var topScores: [ScoreEntry] = []
    
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
                Text("\(score.score)")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                    .padding(.top, 16)
                
                // 統計情報
                Text("Problems Solved: \(score.problemsSolved)\nBonus Points: \(score.bonusPoints)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                
                // ランキング順位
                if let rank = rank {
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
                
                // リーダーボード
                VStack(spacing: 8) {
                    Text("Top Scores")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                    
                    ForEach(Array(topScores.prefix(5).enumerated()), id: \.element.id) { index, entry in
                        let isCurrentScore = entry.id == score.id
                        Text("\(index + 1). \(entry.score) pts")
                            .font(.system(size: 14, weight: isCurrentScore ? .bold : .regular))
                            .foregroundStyle(
                                isCurrentScore ?
                                Color(red: 1.0, green: 0.8, blue: 0.2) :
                                .white.opacity(0.6)
                            )
                    }
                }
                .padding(.top, 40)
                
                Spacer()
            }
        }
        .task {
            // スコアを保存して順位を取得
            rank = await scoreRepository.saveScore(score)
            
            // Top5を取得
            topScores = await scoreRepository.fetchTopScores()
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
