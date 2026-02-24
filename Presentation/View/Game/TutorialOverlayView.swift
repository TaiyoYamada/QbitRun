import SwiftUI
import simd
import UIKit

extension Notification.Name {
    static let tutorialGateTapped = Notification.Name("tutorialGateTapped")
    static let skipTutorialTyping = Notification.Name("skipTutorialTyping")
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
            tutorialPanel

            Spacer()

            nextTutorialButton
        }
        .onAppear {
            announceCurrentStepForVoiceOver()
        }
        .onChange(of: viewModel.currentTutorialStep) { _, _ in
            announceCurrentStepForVoiceOver()
        }
    }

    private var tutorialPanel: some View {
        ZStack(alignment: .topTrailing) {
            tutorialContent
            reviewExitButton

        }
    }

    private var tutorialContent: some View {
        VStack(spacing: 20) {
            tutorialHeader
            tutorialInstruction
        }
        .frame(height: 280, alignment: .top)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tutorial")
        .accessibilityHint("Read the current explanation, then continue.")
    }

    private var tutorialHeader: some View {
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
    }

    private var tutorialInstruction: some View {
        TypewriterText(
            attributedText: viewModel.currentTutorialStep.attributedInstruction(isReviewMode: isReviewMode),
            onFinished: {
                viewModel.tutorialGateEnabled = true
                if viewModel.currentTutorialStep.targetGate == nil {
                    viewModel.showTutorialNextButton = true
                }
            }
        )
        .padding(.horizontal, 15)
        .padding(.vertical, 15)
        .frame(maxWidth: 750, alignment: .center)
        .accessibilitySortPriority(2)
    }

    private var reviewExitButton: some View {
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

    private var nextTutorialButton: some View {
        Button(action: {
            audioManager.playSFX(.button)
            viewModel.advanceTutorialStep()
        }) {
            nextTutorialButtonLabel
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 300)
                .foregroundStyle(viewModel.showTutorialNextButton ? .white : .white.opacity(0.3))
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(nextTutorialButtonBackground)
                .overlay(nextTutorialButtonBorder)
                .compositingGroup()
                .contentTransition(.identity)
                .transaction { $0.animation = nil }
                .scaleEffect(animationScale)
                .shadow(color: viewModel.showTutorialNextButton ? .blue.opacity(0.5) : .clear, radius: 5)
        }
        .disabled(!viewModel.showTutorialNextButton)
        .buttonStyle(.plain)
        .padding(.bottom, 50)
        .accessibilityLabel(nextButtonAccessibilityLabel)
        .accessibilityHint(nextButtonAccessibilityHint)
        .accessibilitySortPriority(4)
    }

    private var nextTutorialButtonLabel: some View {
        ZStack {
            Text("NEXT")
                .opacity(viewModel.currentTutorialStep == .finish ? 0 : 1)

            Text(isReviewMode ? "CLOSE" : "NEXT")
                .opacity(viewModel.currentTutorialStep == .finish ? 1 : 0)
        }
    }

    private var nextTutorialButtonBackground: some View {
        Capsule(style: .continuous)
            .fill(viewModel.showTutorialNextButton ? Color.black.opacity(0.5) : Color.gray.opacity(0.3))
            .overlay {
                if viewModel.showTutorialNextButton {
                    Capsule(style: .continuous)
                        .fill(LinearGradient(
                                  colors: [
                                      Color.cyan.opacity(0.9),
                                      Color(red: 0.24, green: 0.36, blue: 0.82),
                                      Color(red: 0.25, green: 0.08, blue: 0.48)
                                  ],
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing
                              )
                        )
                }
            }
    }

    private var nextTutorialButtonBorder: some View {
        Capsule(style: .continuous)
            .stroke(
                viewModel.showTutorialNextButton ? Color.white.opacity(0.85) : Color.gray.opacity(0.5),
                lineWidth: 5
            )
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
