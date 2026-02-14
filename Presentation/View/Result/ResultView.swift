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
    
    // アニメーション用State
    @State private var showContent = false
    @State private var scoreCount = 0
    
    // MARK: - 初期化
    
    init(score: ScoreEntry, scoreRepository: ScoreRepository, onPlayAgain: @escaping () -> Void, onReturnToMenu: @escaping () -> Void) {
        self._viewModel = State(initialValue: ResultViewModel(score: score, scoreRepository: scoreRepository))
        self.onPlayAgain = onPlayAgain
        self.onReturnToMenu = onReturnToMenu
    }
    
    var body: some View {
            ZStack {
                // MARK: - Layer 1: Background（回路アニメーション無効）
                StandardBackgroundView(showGrid: true, circuitOpacity: 0)
                
                // MARK: - Layer 2: Main Content
                VStack(spacing: 30) {
                    
                    // Header: "MISSION ACCOMPLISHED"
                    Text("MISSION COMPLETE")
                        .font(.custom("Optima-Bold", size: 48))
                        .foregroundStyle(.white)
                        .shadow(color: .cyan.opacity(0.8), radius: 10, x: 0, y: 0)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)
                    
                    // Score Card (Glassmorphism)
                    VStack(spacing: 16) {
                        Text("TOTAL SCORE")
                            .font(.custom("Optima-Bold", size: 16))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        Text("\(scoreCount)")
                            .font(.custom("Optima-Bold", size: 80))
                            .monospacedDigit()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 10)
                            .contentTransition(.numericText())
                        
                        // Rank Badge
                        if let rank = viewModel.rank {
                            HStack(spacing: 8) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.yellow)
                                Text("RANK #\(rank)")
                                    .font(.custom("Optima-Bold", size: 24))
                                    .foregroundStyle(.yellow)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.yellow.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(.yellow.opacity(0.5), lineWidth: 1))
                        } else {
                             Text("Keep Trying for Top 5!")
                                .font(.custom("Optima-Regular", size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        
                        // Details Grid
                        HStack(spacing: 40) {
                            detailItem(label: "PROBLEMS", value: "\(viewModel.score.problemsSolved)")
                            detailItem(label: "BONUS", value: "\(viewModel.score.bonusPoints)")
                        }
                        .padding(.top, 8)
                    }
                    .padding(40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.6), .purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .cyan.opacity(0.2), radius: 20)
                    .frame(width: 500)
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1.0 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.2), value: showContent)
                    
                    // Action Buttons
                    HStack(spacing: 30) {
                        ResultActionButton(
                            title: "RETURN TO BASE",
                            icon: "house.fill",
                            color: .gray,
                            action: onReturnToMenu
                        )
                        
                        ResultActionButton(
                            title: "RETRY MISSION",
                            icon: "arrow.clockwise",
                            color: .cyan,
                            isProminent: true,
                            action: onPlayAgain
                        )
                    }
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.6), value: showContent)
                }
            }
            .task {
                // データロードとアニメーション開始
                await viewModel.loadResults()
                
                withAnimation {
                    showContent = true
                }
                
                // スコアのカウントアップ
                let totalScore = viewModel.score.score
                let duration = 1.5
                let steps = 30
                let stepDelay = duration / Double(steps)
                let stepValue = totalScore / steps
                
                for i in 0...steps {
                    try? await Task.sleep(nanoseconds: UInt64(stepDelay * 1_000_000_000))
                    if i == steps {
                        scoreCount = totalScore
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    } else {
                        scoreCount = stepValue * i
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
    }

    
    private func detailItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.custom("Optima-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.custom("Optima-Bold", size: 24))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - プレビュー

#Preview("リザルト画面") {
    ResultView(
        score: ScoreEntry(score: 1560, problemsSolved: 12, bonusPoints: 360),
        scoreRepository: ScoreRepository(),
        onPlayAgain: { },
        onReturnToMenu: { }
    )
    .preferredColorScheme(.dark)
}
