import SwiftUI

/// ゲーム画面
struct GameView: View {

    @Bindable private var viewModel = GameViewModel()
    @State private var countdownValue: Int = 3
    @State private var showCountdown: Bool = true
    @State private var countdownScale: CGFloat = 0.5
    @State private var countdownOpacity: Double = 0.0
    
    @State private var showSuccessEffect = false
    @State private var showFailureEffect = false
    
    /// ゲームの難易度
    let difficulty: GameDifficulty
    
    /// ゲーム終了時のコールバック
    let onGameEnd: (ScoreEntry) -> Void


    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // MARK: - Layer 1: Background
                StandardBackgroundView(showGrid: false, circuitOpacity: 0)

                // MARK: - Layer 2: Main Content
                VStack(spacing: 5) {
                    // タイマーとスコア
                    headerSection
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .opacity(showCountdown ? 0 : 1) // HUD hidden during countdown
                        .animation(.easeIn(duration: 0.5), value: showCountdown)
                    
                    // ブロッホ球表示エリア
                    spheresSection(geometry: geometry)
                        .opacity(showCountdown ? 0 : 1)

                    // 回路表示エリア
                    circuitSection

                    // ゲートパレット（タップで追加）
                    SwiftUIGatePaletteView { gate in
                        if viewModel.canAddGate && !showCountdown {
                            viewModel.addGate(gate)
                        }
                    }
                    .padding(.top, 30)
                }
                
                // MARK: - Layer 3: Overlay Effects
                EffectOverlayView(
                    showSuccess: $showSuccessEffect,
                    showFailure: $showFailureEffect
                )
                
                // MARK: - Layer 4: Countdown Overlay
                if showCountdown {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    
                    Text(countdownValue > 0 ? "\(countdownValue)" : "START!")
                        .font(.system(size: countdownValue > 0 ? 120 : 100, weight: .bold, design: .rounded))
                        .foregroundStyle(countdownValue > 0 ? .white : .cyan)
                        .shadow(color: (countdownValue > 0 ? Color.white : Color.cyan).opacity(0.8), radius: 20)
                        .scaleEffect(countdownScale)
                        .opacity(countdownOpacity)
                }
            }
        }
        .onAppear {
            viewModel.prepareGame(difficulty: difficulty)
            startCountdown()
        }
        .onChange(of: viewModel.finalScore) { _, newScore in
            if let score = newScore {
                onGameEnd(score)
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
            
            // START!
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

    
    // MARK: - ヘッダー（Glassmorphism）
    
    private var headerSection: some View {
        ZStack {

            Text(String(format: "%02d", viewModel.remainingTime))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(viewModel.isTimeLow ? Color(red: 1.0, green: 0.2, blue: 0.2) : .white)
                .shadow(color: viewModel.isTimeLow ? .red.opacity(0.5) : .cyan.opacity(0.3), radius: 8)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            HStack {
                // Left: Life
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < viewModel.remainingMisses ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundStyle(index < viewModel.remainingMisses ? Color.red : Color.gray.opacity(0.3))
                            .shadow(color: index < viewModel.remainingMisses ? .red.opacity(0.8) : .clear, radius: 4, x: 0, y: 0)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                
                Spacer()

                Text("POINTS：\(viewModel.score)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)

                .padding(.horizontal, 30)
                .padding(.vertical, 12)

            }
        }
    }
    
    // MARK: - ブロッホ球表示（統合ビュー）
    
    private func spheresSection(geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.8

        return VStack() {

            // 凡例
            HStack(spacing: 32) {
                // 現在の状態（赤）
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.2, blue: 0.2))
                        .frame(width: 30, height: 30)
                    Text("CURRENT")
                        .font(.custom("Optima-Bold", size: 30))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // ターゲット状態（金）
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.7))
                        .frame(width: 30, height: 30)
                    Text("TARGET")
                        .font(.custom("Optima-Bold", size: 30))
                        .tracking(1)
                        .foregroundStyle(.yellow.opacity(0.8))
                }
            }
//            .clipShape(Capsule())
//            .overlay(
//                Capsule()
//                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
//            )

            // 単一のブロッホ球で現在とターゲットを同時表示
            BlochSphereViewRepresentable(
                vector: viewModel.currentVector,
                animated: true,
                targetVector: viewModel.targetVector,
                showBackground: false
            )
            .frame(width: size, height: size)
        }
        .padding(.bottom, -100)
    }
    
    // MARK: - 回路表示
    
    private var circuitSection: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.clearCircuit()
                    }
                }) {
                    Text("RESET")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Capsule())
                    }

                Spacer()
            }
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
            showFailureEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showFailureEffect = false
            }
        }
    }
}

#Preview("ゲーム画面", traits: .landscapeLeft) {
    GameView(difficulty: .easy, onGameEnd: { _ in })
}

