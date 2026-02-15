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
    
    @State private var showInfoModal = false
    
    // ... (existing body part)
    
    // MARK: - ヘッダー（Glassmorphism）
    
    private var headerSection: some View {
        ZStack {
            // Center: Circular Timer
            ZStack {
                // 1. Background Track
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                
                // 2. Progress Fill (Clockwise depletion)
                Circle()
                    .trim(from: 1.0 - (CGFloat(viewModel.remainingTime) / 60.0), to: 1.0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
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
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            }
            .frame(width: 115, height: 115)
            .background(
                Circle()
                    .fill(.black.opacity(0.2)) // Darker background for contrast
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)

            HStack {
                // Left: Points (Bordered Frame with Top-Left Label)
                ZStack(alignment: .topLeading) {
                    Text("\(viewModel.score)")
                        .font(.system(size: 45, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .frame(width: 145, height: 85, alignment: .trailing)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.cyan.opacity(0.6), lineWidth: 5)
                        )
                    
                    // Label at Top-Left of the border
                    Text("SCORE")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .offset(x: 10, y: -20)
                }
                
                Spacer()

                // Right: Info Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showInfoModal = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                }
            }
            .padding(.horizontal, 24) // Outer padding for HStack
        }
        .sheet(isPresented: $showInfoModal) {
            GateReferenceView()
                .presentationDetents([.medium, .large])
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

