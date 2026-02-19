import SwiftUI
import simd

extension Notification.Name {
    static let tutorialGateTapped = Notification.Name("tutorialGateTapped")
}

struct TypewriterText: View {
    let attributedText: AttributedString
    let plainText: String
    var onFinished: (() -> Void)? = nil
    @State private var revealedCount: Int = 0
    @State private var isTyping: Bool = false

    init(attributedText: AttributedString, onFinished: (() -> Void)? = nil) {
        self.attributedText = attributedText
        self.plainText = String(attributedText.characters)
        self.onFinished = onFinished
    }

    var body: some View {
        Text(revealedAttributedText)
            .font(.system(size: 23, weight: .medium, design: .monospaced))
            .lineSpacing(2)
            .foregroundStyle(.white)
            .shadow(color: .cyan.opacity(0.8), radius: 2)
            .onChange(of: plainText) { _, _ in
                startTyping()
            }
            .onAppear {
                startTyping()
            }
    }

    private var revealedAttributedText: AttributedString {
        guard revealedCount > 0 else { return AttributedString("") }
        let chars = attributedText.characters
        let endIdx = chars.index(chars.startIndex, offsetBy: min(revealedCount, chars.count))
        return AttributedString(attributedText[chars.startIndex..<endIdx])
    }

    private func startTyping() {
        revealedCount = 0
        isTyping = true
        let totalCount = attributedText.characters.count
        let currentPlainText = plainText

        Task {
            for i in 1...totalCount {
                if currentPlainText != plainText { break }
                revealedCount = i
                let randomDelay = UInt64(Double.random(in: 0.01...0.05) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: randomDelay)
            }
            await MainActor.run {
                isTyping = false
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
                Text(viewModel.currentTutorialStep.title(isReviewMode: isReviewMode))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .cyan, radius: 5)
                    .padding(.top, 35)

                TypewriterText(attributedText: viewModel.currentTutorialStep.attributedInstruction(isReviewMode: isReviewMode), onFinished: {
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
