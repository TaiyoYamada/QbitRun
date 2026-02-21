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
    private let baseFontSize: CGFloat = 23
    private let lineSpacing: CGFloat = 2

    init(attributedText: AttributedString, onFinished: (() -> Void)? = nil) {
        self.attributedText = attributedText
        self.plainText = String(attributedText.characters)
        self.onFinished = onFinished
    }

    var body: some View {
        OutlinedInstructionTextView(
            attributedText: revealedAttributedText,
            baseFontSize: baseFontSize,
            lineSpacing: lineSpacing
        )
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
                onFinished?()
            }
        }
    }
}

private struct OutlinedInstructionTextView: UIViewRepresentable {
    let attributedText: AttributedString
    let baseFontSize: CGFloat
    let lineSpacing: CGFloat
    private let highlightedFontSizeDelta: CGFloat = 2
    private let highlightedStrokeWidth: CGFloat = -1.0

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = makeAttributedString()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        guard let width = proposal.width else {
            return uiView.intrinsicContentSize
        }
        uiView.preferredMaxLayoutWidth = width
        let fittingSize = uiView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: ceil(fittingSize.height))
    }

    private func makeAttributedString() -> NSAttributedString {
        let text = String(attributedText.characters)
        let result = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.7)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = CGSize(width: 0, height: 1)

        result.addAttributes([
            .font: UIFont.monospacedSystemFont(ofSize: baseFontSize, weight: .medium),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle,
            .shadow: shadow
        ], range: fullRange)

        let characters = attributedText.characters
        for run in attributedText.runs {
            guard let style = run[TutorialInstructionHighlightStyleAttribute.self] else { continue }

            let location = characters.distance(from: characters.startIndex, to: run.range.lowerBound)
            let length = characters.distance(from: run.range.lowerBound, to: run.range.upperBound)
            guard length > 0 else { continue }
            let nsRange = NSRange(location: location, length: length)

            result.addAttributes([
                .font: UIFont.monospacedSystemFont(
                    ofSize: baseFontSize + highlightedFontSizeDelta,
                    weight: .medium
                ),
                .foregroundColor: UIColor(TutorialInstructionStylePalette.frontColor(for: style)),
                .strokeColor: TutorialInstructionStylePalette.outlineUIColor(for: style),
                .strokeWidth: highlightedStrokeWidth
            ], range: nsRange)
        }

        return result
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
                    HStack(alignment: .center, spacing: 5) {
                        tutorialNavigationButton(
                            systemName: "chevron.left",
                            isEnabled: viewModel.canGoToPreviousTutorialStep,
                            accessibilityLabel: "Previous tutorial step",
                            accessibilityHint: "Move back to the previous tutorial explanation."
                        ) {
                            viewModel.goToPreviousTutorialStep()
                        }

                        Text(viewModel.currentTutorialStep.title(isReviewMode: isReviewMode))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .cyan, radius: 5)
                            .lineLimit(2)
                            .minimumScaleFactor(0.55)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 450)
                            .transaction { $0.animation = nil }
                            .accessibilitySortPriority(3)

                        tutorialNavigationButton(
                            systemName: "chevron.right",
                            isEnabled: viewModel.canGoToNextReachedTutorialStep,
                            accessibilityLabel: "Next reached tutorial step",
                            accessibilityHint: "Move forward to a tutorial step you've already reached."
                        ) {
                            viewModel.goToNextReachedTutorialStep()
                        }
                    }
                    .frame(maxWidth: 760)
                    .padding(.top, 30)
                    .padding(.horizontal, 10)

                    TypewriterText(attributedText: viewModel.currentTutorialStep.attributedInstruction(isReviewMode: isReviewMode), onFinished: {
                        viewModel.tutorialGateEnabled = true
                        if viewModel.currentTutorialStep.targetGate == nil {
                            viewModel.showTutorialNextButton = true
                        }
                    })
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
                    colors: [Color.white.opacity(0.3), Color.black.opacity(0.5)],
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

    private func tutorialNavigationButton(
        systemName: String,
        isEnabled: Bool,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            audioManager.playSFX(.button)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 37, weight: .bold, design: .rounded))
                .foregroundStyle(isEnabled ? .white : .white.opacity(0.35))
                .shadow(color: isEnabled ? .cyan : .clear,
                        radius: isEnabled ? 5 : 0)
                .frame(width: 68, height: 68)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
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
