import SwiftUI

/// ゲーム画面
struct GameView: View {

    @Bindable private var viewModel = GameViewModel()
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
                VStack(spacing: 0) {
                    // タイマーとスコア
                    headerSection
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // ブロッホ球表示エリア
                    spheresSection(geometry: geometry)

                    // 回路表示エリア
                    circuitSection

                    // ゲートパレット（タップで追加）
                    SwiftUIGatePaletteView { gate in
                        if viewModel.canAddGate {
                            viewModel.addGate(gate)
                        }
                    }
                }
                
                // MARK: - Layer 3: Overlay Effects
                EffectOverlayView(
                    showSuccess: $showSuccessEffect,
                    showFailure: $showFailureEffect
                )
            }
        }
        .onAppear {
            viewModel.startGame(difficulty: difficulty)
        }
            .onChange(of: viewModel.finalScore) { _, newScore in
                if let score = newScore {
                    onGameEnd(score)
                }
            }
    }

    
    // MARK: - ヘッダー（Glassmorphism）
    
    private var headerSection: some View {
        HStack {
            // お手つき残り（ハート） - Neon Style
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < viewModel.remainingMisses ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundStyle(index < viewModel.remainingMisses ? Color.red : Color.gray.opacity(0.3))
                        .shadow(color: index < viewModel.remainingMisses ? .red.opacity(0.8) : .clear, radius: 4, x: 0, y: 0)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
            
            Spacer()
            
            // タイマー - Optima Bold & Large
            Text(String(format: "%02d", viewModel.remainingTime))
                .font(.custom("Optima-Bold", size: 56))

                .monospacedDigit()
                .foregroundStyle(viewModel.isTimeLow ? Color(red: 1.0, green: 0.2, blue: 0.2) : .white)
                .shadow(color: viewModel.isTimeLow ? .red.opacity(0.5) : .cyan.opacity(0.3), radius: 8)
                .contentTransition(.numericText())
                .animation(.default, value: viewModel.remainingTime)
            
            Spacer()
            
            // スコア - Glass Panel
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(viewModel.score)")
                    .font(.custom("Optima-Bold", size: 28))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.4), radius: 4)
                
                Text("pts")
                    .font(.custom("Optima-Regular", size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.3), lineWidth: 1))
        }
    }
    
    // MARK: - ブロッホ球表示（統合ビュー）
    
    private func spheresSection(geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.9

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
        .padding(.vertical, 5)
    }
    
    // MARK: - 回路表示
    
    private var circuitSection: some View {
        VStack(spacing: 0) {
            // Header for Circuit Panel
            HStack {
                Text("QUANTUM CIRCUIT")
                    .font(.custom("Optima-Bold", size: 30))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
                
                // クリアボタン
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.clearCircuit()
                    }
                }) {
                    Text("RESET")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Capsule())
                    }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 4)

            // Circuit Area
                SwiftUICircuitView(
                    gates: $viewModel.circuitGates,
                    onRun: { runCircuit() }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                .frame(height: 100)
        }
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

