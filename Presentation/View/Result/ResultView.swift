
import SwiftUI

struct ResultView: View {

    @State private var viewModel: ResultViewModel

    let onPlayAgain: () -> Void

    let onReturnToMenu: () -> Void

    let audioManager: AudioManager

    @State private var showContent = false
    @State private var scoreCount = 0

    init(score: ScoreEntry, scoreRepository: ScoreRepository, audioManager: AudioManager, onPlayAgain: @escaping () -> Void, onReturnToMenu: @escaping () -> Void) {
        self._viewModel = State(initialValue: ResultViewModel(score: score, scoreRepository: scoreRepository))
        self.audioManager = audioManager
        self.onPlayAgain = onPlayAgain
        self.onReturnToMenu = onReturnToMenu
    }

    var body: some View {
            ZStack {
                UnifiedBackgroundView()

                VStack(spacing: 0) {

                    Spacer()

                    VStack(spacing: 32) {

                        Text("MISSION COMPLETE")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .tracking(4)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(color: .cyan.opacity(0.5), radius: 10)

                        VStack(spacing: 20) {
                            Text("TOTAL SCORE")
                               .font(.system(size: 14, weight: .bold, design: .rounded))
                               .tracking(2)
                               .foregroundStyle(.cyan.opacity(0.8))

                            Text("\(scoreCount)")
                                .font(.system(size: 80, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundStyle(.white)
                                .shadow(color: .cyan.opacity(0.8), radius: 20)
                                .contentTransition(.numericText())
                                .scaleEffect(showContent ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)

                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 40)

                            HStack(spacing: 40) {
                                detailItem(label: "PROBLEMS", value: "\(viewModel.score.problemsSolved)")
                            }
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                        .background(
                            ZStack {
                                Color.black.opacity(0.3)
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(.ultraThinMaterial)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                        Button(action: {
                            audioManager.playSFX(.click)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onReturnToMenu()
                        }) {
                            Text("RETURN TO BASE")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .tracking(1)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .shadow(color: .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 40)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .frame(maxWidth: 500)
                    .padding(20)
                    .scaleEffect(showContent ? 1.0 : 0.95)
                    .opacity(showContent ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.4), value: showContent)

                    Spacer()
                }
            }
            .task {
                audioManager.playBGM(.result)
                await viewModel.loadResults()

                withAnimation {
                    showContent = true
                }

                let totalScore = viewModel.score.score
                if totalScore > 0 {
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
                } else {
                    scoreCount = 0
                }
            }
    }

    private func detailItem(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.3), radius: 8)
        }
    }
}

#Preview("リザルト画面 (Rank 1)") {
    ResultView(
        score: ScoreEntry(score: 5000, problemsSolved: 20),
        scoreRepository: ScoreRepository(defaults: UserDefaults(suiteName: "Preview_Rank1")!),
        audioManager: AudioManager(),
        onPlayAgain: { },
        onReturnToMenu: { }
    )
    .preferredColorScheme(.dark)
}

#Preview("リザルト画面 (Rank 3)") {
    let defaults = UserDefaults(suiteName: "Preview_Rank3")!
    let repo = ScoreRepository(defaults: defaults)

    Task {
        await repo.clearAllScores()
        await repo.saveScore(ScoreEntry(score: 6000, problemsSolved: 25))
        await repo.saveScore(ScoreEntry(score: 5500, problemsSolved: 22))
    }

    return ResultView(
        score: ScoreEntry(score: 5000, problemsSolved: 20),
        scoreRepository: repo,
        audioManager: AudioManager(),
        onPlayAgain: { },
        onReturnToMenu: { }
    )
    .preferredColorScheme(.dark)
}
