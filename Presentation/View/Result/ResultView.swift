
import SwiftUI
import UIKit
import SpriteKit

struct ResultView: View {

    @State private var viewModel: ResultViewModel

    let onPlayAgain: () -> Void

    let onReturnToMenu: () -> Void

    let audioManager: AudioManager

    @State private var showContent = false
    @State private var scoreCount = 0
    @State private var fallScene: QuantumGateFallScene = {
        let scene = QuantumGateFallScene()
        scene.scaleMode = .resizeFill
        return scene
    }()

    init(score: ScoreEntry, scoreRepository: ScoreRepository, audioManager: AudioManager, onPlayAgain: @escaping () -> Void, onReturnToMenu: @escaping () -> Void) {
        self._viewModel = State(initialValue: ResultViewModel(score: score, scoreRepository: scoreRepository))
        self.audioManager = audioManager
        self.onPlayAgain = onPlayAgain
        self.onReturnToMenu = onReturnToMenu
    }

    var body: some View {
            ZStack {
                UnifiedBackgroundView()

                SpriteView(scene: fallScene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 0) {

                    Spacer()

                    VStack(spacing: 50) {

                        Text("GAME CLEAR")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .tracking(8)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.white.opacity(0.85))
                            .shadow(color: .cyan.opacity(0.5), radius: 10)
                            .accessibilityAddTraits(.isHeader)

                        VStack(spacing: 20) {
                            Text("TOTAL SCORE")
                               .font(.system(size: 40, weight: .bold, design: .rounded))
                               .tracking(3)
                               .foregroundStyle(Color(red: 0.2, green: 0.7, blue: 1.0))

                            Text("\(scoreCount)")
                                .font(.system(size: 100, weight: .black, design: .rounded).monospacedDigit())
                                .foregroundStyle(.white)
                                .shadow(color: .cyan.opacity(0.3), radius: 15)
                                .contentTransition(.numericText())
                                .scaleEffect(showContent ? 1.0 : 0.8)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)
                                .accessibilityLabel("Total score")
                                .accessibilityValue("\(scoreCount)")

                            Divider()
                                .background(Color.white.opacity(0.9))
                                .padding(.horizontal, 30)

                            HStack(spacing: 40) {
                                detailItem(label: "PROBLEMS", value: "\(viewModel.score.problemsSolved)")
                            }
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)


                        Button(action: {
                            audioManager.playSFX(.click)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onReturnToMenu()
                        }) {
                            Text("BACK TO MENU")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.vertical, 15)
                                .padding(.horizontal, 35)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan.opacity(0.7),
                                            Color(red: 0.24, green: 0.36, blue: 0.82).opacity(0.7),
                                            Color(red: 0.25, green: 0.08, blue: 0.48).opacity(0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(.white.opacity(0.7), lineWidth: 3)
                                )
                                .shadow(color: .cyan.opacity(0.5), radius: 5)
                                .shadow(color: .cyan.opacity(0.2), radius: 30)
                        }
                        .accessibilityLabel("Return to menu")
                        .accessibilityHint("Go back to main menu.")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 50)
                    .background(
                        RoundedRectangle(cornerRadius: 60)
                            .fill(Color.black.opacity(0.5))
                            .blur(radius: 30)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 60))
                    .buttonStyle(ScaleButtonStyle())
                    .frame(maxWidth: 500)
                    .padding(30)
                    .scaleEffect(showContent ? 1.0 : 0.95)
                    .opacity(showContent ? 1.0 : 0)
                    .animation(.easeOut(duration: 0.4), value: showContent)

                    Spacer()
                }
            }
            .task {
                audioManager.playBGM(.result)
                await viewModel.loadResults()
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .screenChanged, argument: "Mission complete. Total score \(viewModel.score.score).")
                }

                withAnimation {
                    showContent = true
                }

                let totalScore = viewModel.score.score
                if totalScore > 0 {
                    let duration = 1.5
                    
                    let blocksToDrop = min(totalScore / 100, 200)
                    fallScene.startDropping(totalBlocks: blocksToDrop, duration: duration)
                    
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
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(Color.cyan.opacity(0.9))
                .shadow(color: .white.opacity(0.2), radius: 8)

            Text(value)
                .font(.system(size: 60, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.3), radius: 8)
        }
    }
}

#Preview("リザルト画面 (Rank 1)") {
    ResultView(
        score: ScoreEntry(score:20000, problemsSolved: 20),
        scoreRepository: ScoreRepository(defaults: UserDefaults(suiteName: "Preview_Rank1")!),
        audioManager: AudioManager(),
        onPlayAgain: { },
        onReturnToMenu: { }
    )
    .preferredColorScheme(.dark)
}
