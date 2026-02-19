import SwiftUI
import simd
import UIKit

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
            .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(plainText.voiceOverFriendlyTutorialText)
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
    var onExitTapped: (() -> Void)? = nil

    @State private var animationScale: CGFloat = 1.0

    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 20) {
                    Text(viewModel.currentTutorialStep.title(isReviewMode: isReviewMode))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .cyan, radius: 5)
                        .padding(.top, 35)
                        .transaction { $0.animation = nil }
                        .accessibilitySortPriority(3)

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
                        .accessibilitySortPriority(2)
                }
                .frame(height: 280, alignment: .top)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tutorial")
                .accessibilityHint("Read the current explanation, then continue.")

                if isReviewMode {
                    Button(action: {
                        audioManager.playSFX(.button)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onExitTapped?()
                    }) {
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 40, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(.top, 40)
                    .padding(.trailing, 20)
                    .accessibilityLabel("Exit review")
                    .accessibilityHint("Return to the main menu.")
                    .accessibilitySortPriority(1)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.3), Color.black.opacity(0.6)],
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
                .scaleEffect(animationScale)
                .shadow(color: viewModel.showTutorialNextButton ? .cyan : .clear, radius: 7)
            }
            .disabled(!viewModel.showTutorialNextButton)
            .buttonStyle(.plain)
            .padding(.bottom, 50)
            .accessibilityLabel(nextButtonAccessibilityLabel)
            .accessibilityHint(nextButtonAccessibilityHint)
            .accessibilitySortPriority(4)
//            .task(id: viewModel.showTutorialNextButton) {
//                if viewModel.showTutorialNextButton {
//                    try? await Task.sleep(for: .seconds(0.1))
//                    
//                    while !Task.isCancelled {
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            animationScale = 1.15
//                        }
//                        try? await Task.sleep(for: .seconds(0.3))
//                        
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            animationScale = 1.0
//                        }
//                        try? await Task.sleep(for: .seconds(0.3))
//
//                        try? await Task.sleep(for: .seconds(1.0))
//                    }
//                } else {
//                    withAnimation(.easeOut(duration: 0.2)) {
//                        animationScale = 1.0
//                    }
//                }
//            }
        }
        .onAppear {
            announceCurrentStepForVoiceOver()
        }
        .onChange(of: viewModel.currentTutorialStep) { _, _ in
            announceCurrentStepForVoiceOver()
        }
    }

    private var nextButtonAccessibilityLabel: String {
        if viewModel.currentTutorialStep == .finish {
            return isReviewMode ? "Close review" : "Start game"
        }
        return "Next tutorial step"
    }

    private var nextButtonAccessibilityHint: String {
        if !viewModel.showTutorialNextButton {
            if let gate = viewModel.currentTutorialStep.targetGate {
                return "Apply the \(gate.voiceOverName) gate to continue."
            }
            return "Wait for the tutorial text to finish."
        }
        return viewModel.currentTutorialStep == .finish
            ? (isReviewMode ? "Close this review tutorial." : "Finish tutorial and begin the game.")
            : "Move to the next explanation."
    }

    private func announceCurrentStepForVoiceOver() {
        guard UIAccessibility.isVoiceOverRunning else { return }

        let title = viewModel.currentTutorialStep.title(isReviewMode: isReviewMode)
        let instruction = viewModel.currentTutorialStep
            .instruction(isReviewMode: isReviewMode)
            .voiceOverFriendlyTutorialText
        UIAccessibility.post(notification: .screenChanged, argument: "\(title). \(instruction)")
    }
}

private extension QuantumGate {
    var voiceOverName: String {
        switch self {
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .h: return "H"
        case .s: return "S"
        case .t: return "T"
        }
    }
}

private extension String {
    var voiceOverFriendlyTutorialText: String {
        self
            .replacingOccurrences(of: "|0⟩", with: "ket zero")
            .replacingOccurrences(of: "|1⟩", with: "ket one")
            .replacingOccurrences(of: "|+⟩", with: "ket plus")
            .replacingOccurrences(of: "|−⟩", with: "ket minus")
            .replacingOccurrences(of: "|+i⟩", with: "ket plus i")
            .replacingOccurrences(of: "|−i⟩", with: "ket minus i")
            .replacingOccurrences(of: "↔", with: "to")
    }
}
