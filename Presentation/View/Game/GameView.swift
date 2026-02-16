import SwiftUI

/// ゲーム画面
struct GameView: View {

    // MARK: - Dependencies
    @Bindable private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let difficulty: GameDifficulty
    let onGameEnd: (ScoreEntry) -> Void
    let audioManager: AudioManager // [NEW]

    // MARK: - Local State
    @State private var countdownValue: Int = 3
    @State private var showCountdown: Bool = true
    @State private var countdownScale: CGFloat = 0.5
    @State private var countdownOpacity: Double = 0.0
    
    @State private var showSuccessEffect = false
    @State private var showFailureEffect = false
    
    @State private var showExitConfirmation = false
    @State private var showInfoModal = false
    
    @State private var showComboEffect = false
    @State private var comboAnimationTask: Task<Void, Never>? // [NEW] Track animation task

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - Layer 1: Background
                UnifiedBackgroundView()

                // MARK: - Layer 2: Main Content
                VStack(spacing: 5) {
                    // タイマーとスコア
                    headerSection
                        .padding(.bottom, 10)
                        .padding(.horizontal, 24)
                        .animation(.easeIn(duration: 0.5), value: showCountdown)
                    
                    // ブロッホ球表示エリア
                    spheresSection(geometry: geometry)

                    // 回路表示エリア
                    circuitSection

                    // ゲートパレット（タップで追加） + 情報ボタン
                    HStack(alignment: .center, spacing: 20) {
                        SwiftUIGatePaletteView { gate in
                            if viewModel.canAddGate && !showCountdown {
                                audioManager.playSFX(.set)
                                viewModel.addGate(gate)
                            }
                        }
                        
                    }
                    .padding(.top, 20)
                }
                
                // MARK: - Layer 3: Overlay Effects
                EffectOverlayView(
                    showSuccess: $showSuccessEffect,
                    showFailure: $showFailureEffect
                )
                
                // MARK: - Layer 4: Countdown Overlay
                if showCountdown {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    
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
                                    colors: [.white, .cyan, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                              )
                        )
                        .shadow(color: .white.opacity(0.5), radius: 30)
                        .scaleEffect(countdownScale)
                        .opacity(countdownOpacity)
                }
                
                // MARK: - Layer 5: Custom Modal Overlay
                if showExitConfirmation {
                    ExitConfirmationView(
                        title: "END GAME？",
                        message: "Return to the main menu?\nCurrent progress will be lost.",
                        onConfirm: {
                            dismiss()
                        },
                        onCancel: {
                            showExitConfirmation = false
                        }
                    )
                    .zIndex(100)
                    .transition(.opacity)
                }
                
                if showInfoModal {
                    ReferenceModalView {
                        showInfoModal = false
                    }
                    .zIndex(100)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            audioManager.playBGM(.game) // [NEW]
            viewModel.prepareGame(difficulty: difficulty)
            startCountdown()
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
    
    // MARK: - Countdown Logic
    
    private func startCountdown() {
        showCountdown = true
        countdownValue = 3
        
        Task {
            // Count 3, 2, 1
            for i in (1...3).reversed() {
                countdownValue = i
                await animateCountdownStep()
            }
            
            countdownValue = 0
            await animateStartStep()
            
            // End Countdown
            withAnimation(.easeOut(duration: 0.5)) {
                showCountdown = false
            }
            
            // Start Game Timer
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

    
    // MARK: - Header Section
    
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
                                Color(red: 1.0, green: 0.2, blue: 0.2), // Red
                                Color(red: 0.8, green: 0.0, blue: 0.0)  // Dark Red
                            ] : [
                                Color(.purple),
                                Color(.cyan)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: viewModel.remainingTime) // Smooth transition
                
                // 3. Time Text
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
                    .font(.system(size: 47, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.cyan)
                    .frame(width: 160, height: 100, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 60))
                    .overlay(
                        RoundedRectangle(cornerRadius: 60)
                            .stroke(Color.cyan.opacity(0.7), lineWidth: 5)
                    )

                
                Spacer()

                HStack(spacing: 40) {
                    Button(action: {
                        audioManager.playSFX(.button)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showInfoModal = true
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 60, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Button(action: {
                        audioManager.playSFX(.button)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        showExitConfirmation = true
                    }) {
                        Image(systemName: "door.left.hand.open")
                            .font(.system(size: 60, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
    }
    
    // MARK: - ブロッホ球表示（統合ビュー）
    
    private func spheresSection(geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.85

        return ZStack(alignment: .topTrailing) {
            VStack() {

                VStack(alignment: .leading,spacing: 20) {
                    // 現在の状態（赤）
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.8))
                            .frame(width: 30, height: 30)
                        Text("CURRENT")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    // ターゲット状態（金）
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.8))
                            .frame(width: 30, height: 30)
                        Text("TARGET")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(3)
                            .foregroundStyle(.yellow.opacity(0.8))
                    }
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 20)
//                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
//                )
                .offset(
                    x: -geometry.size.width * 0.32,
                    y: geometry.size.height * 0.1
                )

                BlochSphereViewRepresentable(
                    vector: viewModel.currentVector,
                    animated: true,
                    targetVector: viewModel.targetVector,
                    showBackground: false
                )
                .frame(width: size, height: size)
                .opacity(showCountdown ? 0 : 1)
            }
            
            // Persistent Combo Display
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
    
    // MARK: - 回路表示
    
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
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.purple.opacity(0.3), lineWidth: 5)
                        )
                }

                Spacer()
            }
            .padding(.leading, 50)
            .padding(.bottom, 15)

            SwiftUICircuitView(
                gates: $viewModel.circuitGates,
                onRun: { runCircuit() }
            )
            .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 0)
        }
        .opacity(showCountdown ? 0.5 : 1) // Dimmed during countdown
        .disabled(showCountdown) // Disable interaction during countdown
    }
    
    // MARK: - 回路実行
    
    private func runCircuit() {
        guard !viewModel.circuitGates.isEmpty else { return }
        
        // 判定実行
        let result = viewModel.runCircuit()
        
        if result.isCorrect {
            audioManager.playSFX(.success) // [NEW]
            showSuccessEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showSuccessEffect = false
                // 正解したら回路をクリア（アニメーション付き）
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.clearCircuit()
                }
            }
        } else {
            audioManager.playSFX(.miss) // [NEW]
            showFailureEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showFailureEffect = false
            }
        }
    }
    
    // MARK: - Animation Logic
    
    private func triggerComboAnimation() {
        comboAnimationTask?.cancel()
        
        comboAnimationTask = Task { @MainActor in
            // Reset state if needed (though binding should handle it)
            withAnimation(.none) {
                showComboEffect = false
            }
            
            // Small delay to ensure state reset is processed if it was already true
            try? await Task.sleep(for: .milliseconds(50))
            if Task.isCancelled { return }

            // Show effect
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                showComboEffect = true
            }

            // Keep visible for duration
            try? await Task.sleep(for: .milliseconds(700))
            if Task.isCancelled { return }

            // Hide effect
            withAnimation(.easeOut(duration: 0.3)) {
                showComboEffect = false
            }
        }
    }
}

#Preview("ゲーム画面", traits: .landscapeLeft) {
    GameView(difficulty: .easy, onGameEnd: { _ in }, audioManager: AudioManager())
}
