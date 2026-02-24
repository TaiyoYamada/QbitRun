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
    @State private var countdownValue: Int = 3
    @State private var showCountdown: Bool = true
    @State private var countdownPhase: CountdownOverlayView.Phase = .countdown

    @State private var countdownScale: CGFloat = 0.5
    @State private var countdownOpacity: Double = 0.0

    @State private var showSuccessEffect = false
    @State private var showFailureEffect = false

    @State private var tutorialSpotlightFrames: [CGRect] = []
    @State private var elementFrames: [QuantumGate: CGRect] = [:]
    @State private var sphereFrame: CGRect = .zero
    @State private var highlightedGate: QuantumGate?

    @State private var showExitConfirmation = false

    @State private var showComboEffect = false
    @State private var comboAnimationTask: Task<Void, Never>?
    @State private var showPostTutorialGuide = false
    @State private var postTutorialGuideStep: PostTutorialGuideStep = .matchTargetVector
    @State private var postTutorialGuideFocusFrames: [PostTutorialGuideTarget: CGRect] = [:]
    @State private var shouldMarkTutorialCompletionOnGameStart = false
    @State private var isTransitioningToResult = false
    @State private var gameEndTask: Task<Void, Never>?

    private var isGameModalPresented: Bool {
        showExitConfirmation || showPostTutorialGuide || isTransitioningToResult
    }

    private var isInteractionLocked: Bool {
        showCountdown || showExitConfirmation || showPostTutorialGuide || isTransitioningToResult
    }

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
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                showExitConfirmation = true
                            }
                        )
                        .padding(.bottom, 10)
                        .padding(.horizontal, 24)
                        .animation(.easeIn(duration: 0.5), value: showCountdown)
                    } else {
                        Spacer()
                            .frame(height: 170)
                    }

                    GameBlochSphereSection(
                        currentVector: viewModel.currentVector,
                        targetVector: viewModel.targetVector,
                        isTutorialActive: viewModel.isTutorialActive,
                        showCountdown: showCountdown,
                        comboCount: viewModel.comboCount,
                        lastComboBonus: viewModel.lastComboBonus,
                        showComboEffect: $showComboEffect,
                        geometry: geometry
                    )

                    if !viewModel.isTutorialActive {
                        GameCircuitSection(
                            circuitGates: $viewModel.circuitGates,
                            maxGates: viewModel.maxGates,
                            showCountdown: showCountdown,
                            audioManager: audioManager,
                            onClear: { viewModel.clearCircuit() },
                            onRun: { runCircuit() },
                            onGateRemove: { index in viewModel.removeGate(at: index) }
                        )
                    }

                    HStack(alignment: .center, spacing: 20) {
                        SwiftUIGatePaletteView(
                            highlightedGate: highlightedGate,
                            allDisabled: viewModel.isTutorialActive && (viewModel.currentTutorialStep.targetGate == nil || !viewModel.tutorialGateEnabled)
                        ) { gate in
                            if viewModel.isTutorialActive {
                                audioManager.playSFX(.set)
                                viewModel.handleTutorialGateTap(gate)
                            } else if viewModel.canAddGate && !showCountdown {
                                audioManager.playSFX(.set)
                                viewModel.addGate(gate)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .anchorPreference(key: PostTutorialGuideFocusPreferenceKey.self, value: .bounds) { anchor in
                        [.gatePalette: anchor]
                    }
                }
                .allowsHitTesting(!isInteractionLocked)
                .accessibilityHidden(isGameModalPresented)

                EffectOverlayView(
                    showSuccess: $showSuccessEffect,
                    showFailure: $showFailureEffect
                )
                .accessibilityHidden(isGameModalPresented)

                if showPostTutorialGuide {
                    PostTutorialGuideOverlayView(
                        step: postTutorialGuideStep,
                        focusFrames: postTutorialGuideFocusFrames,
                        onNextTapped: {
                            advancePostTutorialGuide()
                        }
                    )
                    .zIndex(250)
                    .transition(.opacity)
                }

                if showCountdown {
                    CountdownOverlayView(
                        phase: countdownPhase,
                        value: countdownValue,
                        scale: countdownScale,
                        opacity: countdownOpacity
                    )
                    .accessibilityHidden(isGameModalPresented)
                }

                if showExitConfirmation {
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
                            showExitConfirmation = false
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
                            showExitConfirmation = true
                        }
                    )
                    .zIndex(200)
                    .transition(.opacity)
                    .accessibilityHidden(isGameModalPresented)
                }
            }
            .simultaneousGesture(
                SpatialTapGesture().onEnded { value in
                    if isInteractionLocked { return }

                    if viewModel.isTutorialActive {
                        if showExitConfirmation { return }

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
                showCountdown = false
            } else {
                startCountdown()
            }
        }
        .onChange(of: viewModel.isTutorialActive) { _, isActive in
            if isActive {
                self.highlightedGate = nil
                updateSpotlightFrames(animated: false)
            } else {
                highlightedGate = nil
                updateSpotlightFrames(animated: false)

                if isReviewMode {
                    dismiss()
                } else if isInitialTutorialFlow {
                    beginPostTutorialGuide()
                } else {
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        startCountdown()
                    }
                }
            }
        }
        .onChange(of: viewModel.currentTutorialStep) { _, step in
            if viewModel.isTutorialActive {
                self.highlightedGate = nil
                updateSpotlightFrames(animated: false)
            }
        }
        .onChange(of: viewModel.tutorialGateEnabled) { _, enabled in
            if enabled && viewModel.isTutorialActive {
                self.highlightedGate = viewModel.currentTutorialStep.targetGate
                updateSpotlightFrames()
            }
        }
        .onChange(of: viewModel.finalScore) { _, newScore in
            guard let score = newScore else { return }

            if viewModel.remainingTime <= 0 {
                startTimeUpTransition(with: score)
            } else if !isTransitioningToResult {
                onGameEnd(score)
            }
        }
        .onChange(of: viewModel.comboCount) { _, newCount in
            if newCount >= 2 {
                triggerComboAnimation()
            }
        }
        .onChange(of: viewModel.remainingTime) { _, newValue in
            if newValue == 10 {
                announceForVoiceOver("10 seconds remaining.")
            }
        }
        .onDisappear {
            comboAnimationTask?.cancel()
            gameEndTask?.cancel()
        }
    }

    // MARK: - Spotlight

    private func updateSpotlightFrames(animated: Bool = true) {
        var frames: [CGRect] = []

        if !sphereFrame.isEmpty {
             frames.append(sphereFrame)
        }

        if let gate = highlightedGate, let rect = elementFrames[gate] {
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

    // MARK: - Countdown

    private func startCountdown() {
        showCountdown = true
        countdownValue = 3
        countdownPhase = .countdown

        Task {
            for i in (1...3).reversed() {
                countdownValue = i
                countdownPhase = .countdown
                announceForVoiceOver("\(i)")
                await animateCountdownStep()
            }

            countdownValue = 0
            countdownPhase = .start
            announceForVoiceOver("Start.")
            await animateStartStep()

            withAnimation(.easeOut(duration: 0.5)) {
                showCountdown = false
            }

            viewModel.startGameLoop()

            if shouldMarkTutorialCompletionOnGameStart {
                hasCompletedTutorial = true
                shouldMarkTutorialCompletionOnGameStart = false
            }
        }
    }

    private func startTimeUpTransition(with score: ScoreEntry) {
        guard !isTransitioningToResult else { return }

        isTransitioningToResult = true
        gameEndTask?.cancel()
        gameEndTask = Task { @MainActor in
            showCountdown = true
            countdownPhase = .timeUp
            await animateTimeUpStep()

            if Task.isCancelled { return }
            onGameEnd(score)
        }
    }

    @MainActor
    private func animateCountdownStep() async {
        countdownScale = 0.5
        countdownOpacity = 0.0

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            countdownScale = 1.2
            countdownOpacity = 1.0
        }

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        try? await Task.sleep(for: .milliseconds(600))

        withAnimation(.easeIn(duration: 0.2)) {
            countdownScale = 1.5
            countdownOpacity = 0.0
        }

        try? await Task.sleep(for: .milliseconds(200))
    }

    @MainActor
    private func animateStartStep() async {
        countdownScale = 0.5
        countdownOpacity = 0.0

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            countdownScale = 1.5
            countdownOpacity = 1.0
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        try? await Task.sleep(for: .milliseconds(800))

        withAnimation(.easeOut(duration: 0.3)) {
            countdownScale = 2.0
            countdownOpacity = 0.0
        }
    }

    @MainActor
    private func animateTimeUpStep() async {
        countdownScale = 0.5
        countdownOpacity = 0.0
        announceForVoiceOver("Time up.")

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            countdownScale = 1.5
            countdownOpacity = 1.0
        }

        UINotificationFeedbackGenerator().notificationOccurred(.warning)

        try? await Task.sleep(for: .milliseconds(1900))
    }

    // MARK: - Post Tutorial Guide

    private func beginPostTutorialGuide() {
        shouldMarkTutorialCompletionOnGameStart = true
        postTutorialGuideStep = .matchTargetVector

        withAnimation(.easeOut(duration: 0.2)) {
            showPostTutorialGuide = true
        }
    }

    private func advancePostTutorialGuide() {
        audioManager.playSFX(.button)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if let next = PostTutorialGuideStep(rawValue: postTutorialGuideStep.rawValue + 1) {
            withAnimation(.easeInOut(duration: 0.25)) {
                postTutorialGuideStep = next
            }
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            showPostTutorialGuide = false
        }

        Task {
            try? await Task.sleep(for: .milliseconds(250))
            startCountdown()
        }
    }

    // MARK: - Circuit

    private func runCircuit() {
        guard !viewModel.circuitGates.isEmpty else { return }

        let result = viewModel.runCircuit()

        if result.isCorrect {
            audioManager.playSFX(.success)
            showSuccessEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showSuccessEffect = false
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.clearCircuit()
                }
            }
        } else {
            audioManager.playSFX(.miss)
            showFailureEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showFailureEffect = false
            }
        }
    }

    // MARK: - Accessibility

    private func announceForVoiceOver(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    // MARK: - Combo

    private func triggerComboAnimation() {
        comboAnimationTask?.cancel()

        comboAnimationTask = Task { @MainActor in
            withAnimation(.none) {
                showComboEffect = false
            }

            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showComboEffect = true
            }

            try? await Task.sleep(for: .milliseconds(700))
            if Task.isCancelled { return }

            withAnimation(.easeOut(duration: 0.3)) {
                showComboEffect = false
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
