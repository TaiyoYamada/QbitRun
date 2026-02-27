import SwiftUI
import UIKit

struct GameView: View {

    @State private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss

    let difficulty: GameDifficulty
    let isTutorial: Bool
    let isReviewMode: Bool
    let onGameEnd: (ScoreEntry) -> Void
    let audioManager: AudioManager

    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false

    @State private var tutorialSpotlightFrames: [CGRect] = []
    @State private var elementFrames: [QuantumGate: CGRect] = [:]
    @State private var sphereFrame: CGRect = .zero
    @State private var postTutorialGuideFocusFrames: [PostTutorialGuideTarget: CGRect] = [:]

    private var isInitialTutorialFlow: Bool {
        isTutorial && !isReviewMode
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                UnifiedBackgroundView()

                VStack(spacing: 5) {
                    if !viewModel.isTutorialActive {
                        GameHeaderView(
                            remainingTime: viewModel.remainingTime,
                            score: viewModel.score,
                            isTimeLow: viewModel.isTimeLow,
                            isTutorialActive: viewModel.isTutorialActive,
                            onExitTapped: {
                                audioManager.playSFX(.button)
                                viewModel.mediumFeedback.impactOccurred()
                                viewModel.showExitConfirmation = true
                            }
                        )
                        .padding(.bottom, 10)
                        .padding(.horizontal, 24)
                        .animation(.easeIn(duration: 0.5), value: viewModel.showCountdown)
                        .accessibilitySortPriority(90)
                    } else {
                        Spacer()
                            .frame(height: 170)
                    }

                    GameBlochSphereSection(
                        currentVector: viewModel.currentVector,
                        targetVector: viewModel.targetVector,
                        isTutorialActive: viewModel.isTutorialActive,
                        showCountdown: viewModel.showCountdown,
                        comboCount: viewModel.comboCount,
                        lastComboBonus: viewModel.lastComboBonus,
                        showComboEffect: $viewModel.showComboEffect,
                        geometry: geometry
                    )
                    .accessibilitySortPriority(50)

                    if !viewModel.isTutorialActive {
                        GameCircuitSection(
                            circuitGates: $viewModel.circuitGates,
                            maxGates: viewModel.maxGates,
                            showCountdown: viewModel.showCountdown,
                            audioManager: audioManager,
                            onClear: { viewModel.clearCircuit() },
                            onRun: { viewModel.runCircuit(audioManager: audioManager) },
                            onGateRemove: { index in viewModel.removeGate(at: index) }
                        )
                        .accessibilitySortPriority(30)
                    }

                    HStack(alignment: .center, spacing: 20) {
                        SwiftUIGatePaletteView(
                            highlightedGate: viewModel.highlightedGate,
                            allDisabled: viewModel.isTutorialActive && (viewModel.currentTutorialStep.targetGate == nil || !viewModel.tutorialGateEnabled)
                        ) { gate in
                            if viewModel.isTutorialActive {
                                audioManager.playSFX(.set)
                                viewModel.handleTutorialGateTap(gate)
                            } else if viewModel.canAddGate && !viewModel.showCountdown {
                                audioManager.playSFX(.set)
                                viewModel.addGate(gate)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .accessibilitySortPriority(20)
                    .anchorPreference(key: PostTutorialGuideFocusPreferenceKey.self, value: .bounds) { anchor in
                        [.gatePalette: anchor]
                    }
                }
                .allowsHitTesting(!viewModel.isInteractionLocked)
                .accessibilityHidden(viewModel.isGameModalPresented)

                EffectOverlayView(
                    showSuccess: $viewModel.showSuccessEffect,
                    showFailure: $viewModel.showFailureEffect
                )
                .accessibilityHidden(viewModel.isGameModalPresented)

                if viewModel.showPostTutorialGuide {
                    PostTutorialGuideOverlayView(
                        step: viewModel.postTutorialGuideStep,
                        focusFrames: postTutorialGuideFocusFrames,
                        onNextTapped: {
                            viewModel.advancePostTutorialGuide(audioManager: audioManager)
                        }
                    )
                    .zIndex(250)
                    .transition(.opacity)
                }

                if viewModel.showCountdown {
                    CountdownOverlayView(
                        phase: viewModel.countdownPhase,
                        value: viewModel.countdownValue,
                        scale: viewModel.countdownScale,
                        opacity: viewModel.countdownOpacity
                    )
                    .accessibilityHidden(viewModel.isGameModalPresented)
                }

                if viewModel.showExitConfirmation {
                    ExitConfirmationView(
                        title: viewModel.isTutorialActive && isReviewMode ? "EXIT REVIEW？" : "END GAME？",
                        message: viewModel.isTutorialActive && isReviewMode
                            ? "Return to the main menu?"
                            : "Return to the main menu?\nCurrent progress will be lost.",
                        confirmText: viewModel.isTutorialActive && isReviewMode ? "EXIT" : "EXIT GAME",
                        onConfirm: {
                            audioManager.playSFX(.button)
                            dismiss()
                        },
                        onCancel: {
                            audioManager.playSFX(.cancel)
                            viewModel.showExitConfirmation = false
                        }
                    )
                    .zIndex(300)
                    .transition(.opacity)
                }

                if viewModel.isTutorialActive {
                    TutorialOverlayView(
                        viewModel: viewModel,
                        spotlightFrames: tutorialSpotlightFrames,
                        audioManager: audioManager,
                        isReviewMode: isReviewMode,
                        onExitTapped: {
                            viewModel.showExitConfirmation = true
                        }
                    )
                    .zIndex(200)
                    .transition(.opacity)
                    .accessibilityHidden(viewModel.isGameModalPresented)
                }
            }
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    if viewModel.isInteractionLocked { return }

                    if viewModel.isTutorialActive {
                        if viewModel.showExitConfirmation { return }

                        let isExitButtonArea = value.location.x > geometry.size.width - 120 && value.location.y < 120
                        if isExitButtonArea { return }

                        NotificationCenter.default.post(name: .skipTutorialTyping, object: nil)
                    }
                }
            )
            .onPreferenceChange(BoundsPreferenceKey.self) { preferences in
                var newFrames: [QuantumGate: CGRect] = [:]
                for (gate, anchor) in preferences {
                    newFrames[gate] = geometry[anchor]
                }
                if self.elementFrames != newFrames {
                    self.elementFrames = newFrames
                    updateSpotlightFrames(animated: false)
                }
            }
            .onPreferenceChange(SphereBoundsPreferenceKey.self) { anchor in
                if let anchor = anchor {
                   let newFrame = geometry[anchor]
                    if self.sphereFrame != newFrame {
                       self.sphereFrame = newFrame
                       updateSpotlightFrames(animated: false)
                   }
                }
            }
            .onPreferenceChange(PostTutorialGuideFocusPreferenceKey.self) { preferences in
                var resolved: [PostTutorialGuideFocusRegion: CGRect] = [:]
                for (region, anchor) in preferences {
                    resolved[region] = geometry[anchor]
                }

                var newFrames: [PostTutorialGuideTarget: CGRect] = [:]

                if let sphere = resolved[.sphere], !sphere.isEmpty {
                    newFrames[.sphere] = sphere
                }

                if let gatePalette = resolved[.gatePalette], !gatePalette.isEmpty {
                    newFrames[.gatePalette] = gatePalette
                }

                let scoreAndTimeFrame = [resolved[.score], resolved[.timer]]
                    .compactMap { $0 }
                    .reduce(CGRect.null) { partial, frame in
                        partial.isNull ? frame : partial.union(frame)
                    }

                if !scoreAndTimeFrame.isNull {
                    newFrames[.scoreAndTime] = scoreAndTimeFrame
                }

                if self.postTutorialGuideFocusFrames != newFrames {
                    self.postTutorialGuideFocusFrames = newFrames
                }
            }
        }

        .onAppear {
            audioManager.playBGM(.game)
            viewModel.prepareGame(difficulty: difficulty)

            if isTutorial {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    viewModel.startTutorial()
                }
                viewModel.showCountdown = false
            } else {
                viewModel.startCountdown()
            }
        }
        .onChange(of: viewModel.isTutorialActive) { _, isActive in
            if isActive {
                viewModel.highlightedGate = nil
                updateSpotlightFrames(animated: false)
            } else {
                viewModel.highlightedGate = nil
                updateSpotlightFrames(animated: false)

                if isReviewMode {
                    dismiss()
                } else if isInitialTutorialFlow {
                    viewModel.beginPostTutorialGuide()
                } else {
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        viewModel.startCountdown()
                    }
                }
            }
        }
        .onChange(of: viewModel.currentTutorialStep) { _, step in
            if viewModel.isTutorialActive {
                viewModel.highlightedGate = nil
                updateSpotlightFrames(animated: false)
            }
        }
        .onChange(of: viewModel.tutorialGateEnabled) { _, enabled in
            if enabled && viewModel.isTutorialActive {
                viewModel.highlightedGate = viewModel.currentTutorialStep.targetGate
                updateSpotlightFrames()
            }
        }
        .onChange(of: viewModel.finalScore) { _, newScore in
            guard let score = newScore else { return }

            if viewModel.remainingTime <= 0 {
                viewModel.startTimeUpTransition(with: score, onGameEnd: onGameEnd)
            } else if !viewModel.isTransitioningToResult {
                onGameEnd(score)
            }
        }
        .onChange(of: viewModel.comboCount) { _, newCount in
            if newCount >= 2 {
                viewModel.triggerComboAnimation()
            }
        }
        .onChange(of: viewModel.remainingTime) { _, newValue in
            if newValue == 10 {
                viewModel.announceForVoiceOver("10 seconds remaining.")
            }
        }
        .onChange(of: viewModel.showCountdown) { _, isShowing in
            if !isShowing && viewModel.shouldMarkTutorialCompletionOnGameStart {
                hasCompletedTutorial = true
                viewModel.shouldMarkTutorialCompletionOnGameStart = false
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }



    private func updateSpotlightFrames(animated: Bool = true) {
        var frames: [CGRect] = []

        if !sphereFrame.isEmpty {
             frames.append(sphereFrame)
        }

        if let gate = viewModel.highlightedGate, let rect = elementFrames[gate] {
            frames.append(rect)
        }

        if animated {
            withAnimation {
                self.tutorialSpotlightFrames = frames
            }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.tutorialSpotlightFrames = frames
            }
        }
    }
}

struct SphereBoundsPreferenceKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
