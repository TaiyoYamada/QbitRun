import SwiftUI

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

    private var isGameModalPresented: Bool {
        showExitConfirmation
    }


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                UnifiedBackgroundView()

                VStack(spacing: 5) {
                    if !viewModel.isTutorialActive {
                        headerSection
                            .padding(.bottom, 10)
                            .padding(.horizontal, 24)
                            .animation(.easeIn(duration: 0.5), value: showCountdown)
                    } else {
                        Spacer()
                            .frame(height: 170)
                    }

                    spheresSection(geometry: geometry)

                    if !viewModel.isTutorialActive {
                        circuitSection
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
                }
                .accessibilityHidden(isGameModalPresented)

                EffectOverlayView(
                    showSuccess: $showSuccessEffect,
                    showFailure: $showFailureEffect
                )
                .accessibilityHidden(isGameModalPresented)

                if showCountdown {
                    Color.black.opacity(0.3).ignoresSafeArea()
                        .accessibilityHidden(isGameModalPresented)

                    Text(countdownValue > 0 ? "\(countdownValue)" : "START！")
                        .tracking(2)
                        .font(.system(size: countdownValue > 0 ? 140 : 110,
                                      weight: .bold,
                                      design: .rounded))
                        .foregroundStyle(
                            countdownValue > 0
                            ? AnyShapeStyle(.white)
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.65, green: 0.95, blue: 1.0),
                                        Color(red: 0.35, green: 0.50, blue: 0.95),
                                        Color(red: 0.45, green: 0.20, blue: 0.70)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                              )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 30)
                        .scaleEffect(countdownScale)
                        .opacity(countdownOpacity)
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
                TapGesture().onEnded {
                    if viewModel.isTutorialActive {
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
                hasCompletedTutorial = true
                highlightedGate = nil
                updateSpotlightFrames(animated: false)

                if isReviewMode {
                    dismiss()
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
            if let score = newScore {
                onGameEnd(score)
            }
        }
        .onChange(of: viewModel.comboCount) { _, newCount in
            if newCount >= 2 {
                triggerComboAnimation()
            }
        }

    }

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

    private var scoreColor: AnyShapeStyle {
        let score = viewModel.score
        switch score {
        case 30000...:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white, .cyan, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case 10000...:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case 5000...:
            return AnyShapeStyle(.purple)
        case 1000...:
            return AnyShapeStyle(.cyan)
        default:
            return AnyShapeStyle(.white)
        }
    }

    private func startCountdown() {
        showCountdown = true
        countdownValue = 3

        Task {
            for i in (1...3).reversed() {
                countdownValue = i
                await animateCountdownStep()
            }

            countdownValue = 0
//            audioManager.playSFX(.start)
            await animateStartStep()

            withAnimation(.easeOut(duration: 0.5)) {
                showCountdown = false
            }

            viewModel.startGameLoop()
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

    private var headerSection: some View {
        ZStack {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 1.0 - (CGFloat(viewModel.remainingTime) / 60.0), to: 1.0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: viewModel.isTimeLow ? [
                                Color(red: 1.0, green: 0.2, blue: 0.2),
                                Color(red: 0.8, green: 0.0, blue: 0.0)
                            ] : [
                                Color(red: 0.65, green: 0.95, blue: 1.0),
                                Color(red: 0.35, green: 0.50, blue: 0.95),
                                Color(red: 0.45, green: 0.20, blue: 0.70)

                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: viewModel.remainingTime)

                Text(String(format: "%d", viewModel.remainingTime))
                    .font(.system(size: 53, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(viewModel.isTimeLow ? Color(red: 1.0, green: 0.2, blue: 0.2) : .white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            }
            .frame(width: 115, height: 115)
            .background(
                Circle()
                    .fill(.black.opacity(0.2))
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)

            HStack {
                Text("\(viewModel.score)")
                    .font(.system(size: 45, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(scoreColor)
                    .frame(width: 170, height: 110, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        ZStack {
                            Color.clear
                            Color.black.opacity(0.2)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 60))
                    .overlay(
                        RoundedRectangle(cornerRadius: 60)
                            .stroke(Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.9), lineWidth: 5)
                    )
                    .padding(.leading, 30)

                Spacer()

                Button(action: {
                    audioManager.playSFX(.button)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showExitConfirmation = true
                }) {
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 60, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.trailing, 20)
                .accessibilityLabel("Exit game")
                .accessibilityHint("Open exit confirmation.")
            }
        }
        .opacity(viewModel.isTutorialActive ? 0 : 1)
    }

    private func spheresSection(geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.85

        return ZStack(alignment: .topTrailing) {
            VStack() {
                if !viewModel.isTutorialActive {
                    VStack(alignment: .leading,spacing: 10) {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.8))
                                .frame(width: 25, height: 25)
                            Text("CURRENT")
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .tracking(3)
                                .foregroundStyle(Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.8))
                        }
                        HStack(spacing: 15) {
                            Circle()
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 25, height: 25)
                            Text("TARGET")
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .tracking(3)
                                .foregroundStyle(Color.white.opacity(0.8))
                        }
                        HStack(spacing: 15) {
                            Circle()
                                .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8))
                                .frame(width: 25, height: 25)
                            Text("MATCH")
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .tracking(3)
                                .foregroundStyle(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8))
                        }
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                    .offset(
                        x: -geometry.size.width * 0.32,
                        y: geometry.size.height * 0.08
                    )
                }

                BlochSphereViewRepresentable(
                    vector: viewModel.currentVector,
                    animated: !viewModel.isTutorialActive,
                    targetVector: viewModel.isTutorialActive ? nil : viewModel.targetVector,
                    showBackground: false
                )
                .frame(width: size, height: size)
                .opacity(showCountdown ? 0 : 1)
                .anchorPreference(key: SphereBoundsPreferenceKey.self, value: .bounds) { anchor in
                    anchor
                }
            }

            ComboEffectView(
                comboCount: viewModel.comboCount,
                bonus: viewModel.lastComboBonus,
                isVisible: $showComboEffect
            )
            .offset(x: 10, y: 110)
        }
        .padding(.top, -60)
        .padding(.bottom, -110)
    }

    private var circuitSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    audioManager.playSFX(.clear)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.clearCircuit()
                    }
                }) {
                    Text("CLEAR")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.6), lineWidth: 5)
                        )
                }
                .accessibilityLabel("Clear circuit")
                .accessibilityHint("Remove all gates from the current circuit.")

                Spacer()
            }
            .padding(.leading, 73)
            .padding(.bottom, 15)

            SwiftUICircuitView(
                gates: $viewModel.circuitGates,
                maxSlots: viewModel.maxGates,
                onRun: { runCircuit() },
                onGateRemove: { index in
                    audioManager.playSFX(.clear)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.removeGate(at: index)
                }
            )
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 0)
        }
        .opacity(showCountdown ? 0.5 : 1)
        .disabled(showCountdown)
    }

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
