import SwiftUI
import simd

extension Notification.Name {
    static let tutorialGateTapped = Notification.Name("tutorialGateTapped")
}

struct TypewriterText: View {
    let text: String
    var onFinished: (() -> Void)? = nil
    @State private var displayedText: String = ""
    @State private var charIndex: Int = 0

    var body: some View {
        Text(displayedText)
            .font(.system(size: 23, weight: .medium, design: .monospaced))
            .lineSpacing(2)
            .foregroundStyle(.white)
            .shadow(color: .cyan.opacity(0.8), radius: 2)
            .onChange(of: text) { _, newValue in
                startTyping(newValue)
            }
            .onAppear {
                startTyping(text)
            }
    }

    private func startTyping(_ newText: String) {
        displayedText = ""
        charIndex = 0

        Task {
            for char in newText {
                if newText != text { break }
                displayedText.append(char)
                let randomDelay = UInt64(Double.random(in: 0.01...0.05) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: randomDelay)
            }
            await MainActor.run {
                onFinished?()
            }
        }
    }
}

struct TutorialOverlayView: View {
    @Bindable var viewModel: GameViewModel
    let spotlightFrames: [CGRect]
    let audioManager: AudioManager
    let isReviewMode: Bool

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Text(viewModel.currentTutorialStep.title)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .cyan, radius: 5)
                    .padding(.top, 35)

                TypewriterText(text: viewModel.currentTutorialStep.instruction, onFinished: {
                    viewModel.tutorialGateEnabled = true
                    if viewModel.currentTutorialStep.targetGate == nil {
                        viewModel.showTutorialNextButton = true
                    }
                })
                    .font(.system(size: 23, weight: .bold, design: .rounded).monospacedDigit())
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .frame(maxWidth: 750, alignment: .center)
            }
            .frame(height: 280, alignment: .top)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.4), Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            Spacer()

            Button(action: {
                audioManager.playSFX(.button)
                viewModel.advanceTutorialStep()
            }) {
                HStack(spacing: 15) {
                    Text(viewModel.currentTutorialStep == .finish
                         ? (isReviewMode ? "CLOSE" : "START GAME")
                         : "NEXT")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                }
                .foregroundStyle(viewModel.showTutorialNextButton ? .white : .white.opacity(0.3))
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(
                    ZStack {
                        if viewModel.showTutorialNextButton {
                            Color.cyan
                            Color.black.opacity(0.7)
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 50))
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(viewModel.showTutorialNextButton ? Color.white.opacity(0.85) : Color.gray.opacity(0.5), lineWidth: 5)
                )
                .shadow(color: viewModel.showTutorialNextButton ? .cyan : .clear, radius: 7)
            }
            .disabled(!viewModel.showTutorialNextButton)
            .buttonStyle(.plain)
            .padding(.bottom, 50)
        }
    }
}
