import SwiftUI

/// ゲーム画面
struct GameView: View {

    @State private var viewModel = GameViewModel()
    @State private var showSuccessEffect = false
    @State private var showFailureEffect = false
    @State private var circuitGates: [QuantumGate] = []
    
    /// ゲームの難易度
    let difficulty: GameDifficulty
    
    /// ゲーム終了時のコールバック
    let onGameEnd: (ScoreEntry) -> Void
    
    var body: some View {
        ZStack {
            // MARK: - Layer 1: Background
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
                spheresSection
                
                Spacer()
                
                // 回路表示エリア
                circuitSection
                    .padding(.horizontal, 24)
                
                Spacer()
                
                // ゲートパレット（タップで追加）
                SwiftUIGatePaletteView { gate in
                    if circuitGates.count < 5 {
                        circuitGates.append(gate)
                        viewModel.addGate(gate)
                    }
                }
                // Palette has its own padding/styling now, but we add safe area padding
                .padding(.bottom, 8)
            }
            
            // MARK: - Layer 3: Overlay Effects
            EffectOverlayView(
                showSuccess: $showSuccessEffect,
                showFailure: $showFailureEffect
            )
        }
        .onAppear {
            viewModel.startGame(difficulty: difficulty)
        }
        .onChange(of: viewModel.finalScore) { _, newScore in
            if let score = newScore {
                onGameEnd(score)
            }
        }
        .onChange(of: circuitGates) { _, newGates in
            // 回路ゲートが変更されたらViewModelを更新
            syncCircuitToViewModel()
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
            .glassEffect(in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
            
            Spacer()
            
            // タイマー - Optima Bold & Large
            Text(String(format: "%02d", viewModel.remainingTime))
                .font(.custom("Optima-Bold", size: 56))
                .presentationCornerRadius(8) // Just a modifier to create spacing logic if needed
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
            .glassEffect(in: RoundedRectangle(cornerRadius: 12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.3), lineWidth: 1))
        }
    }
    
    // MARK: - ブロッホ球表示（統合ビュー）
    
    private var spheresSection: some View {
        VStack(spacing: 12) {
            // 単一のブロッホ球で現在とターゲットを同時表示
            BlochSphereViewRepresentable(
                vector: viewModel.currentVector,
                animated: true,
                targetVector: viewModel.targetVector,  // ゴースト表示
                showBackground: false
            )
            .frame(width: 400, height: 400)
            
            // 凡例
            HStack(spacing: 32) {
                // 現在の状態（赤）
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.9, green: 0.2, blue: 0.2))
                        .frame(width: 12, height: 12)
                    Text("CURRENT")
                        .font(.custom("Optima-Bold", size: 14))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                // ターゲット状態（金）
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.7))
                        .frame(width: 12, height: 12)
                    Text("TARGET")
                        .font(.custom("Optima-Bold", size: 14))
                        .tracking(1)
                        .foregroundStyle(.yellow.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassEffect(in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - 回路表示
    
    private var circuitSection: some View {
        VStack(spacing: 0) {
            // Header for Circuit Panel
            HStack {
                Text("QUANTUM CIRCUIT")
                    .font(.custom("Optima-Bold", size: 14))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.5))
                
                Spacer()
                
                // クリアボタン
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        circuitGates.removeAll()
                    }
                    viewModel.clearCircuit()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("CLEAR")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 4)

            // Circuit Area
                SwiftUICircuitView(
                    gates: $circuitGates,
                    onRun: { runCircuit() }
                )
                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2).frame(height: 100) // Height constraint for stability
        }
    }
    
    // MARK: - 回路実行
    
    private func runCircuit() {
        guard !circuitGates.isEmpty else { return }
        
        // 判定実行
        let result = viewModel.runCircuit()
        
        if result.isCorrect {
            showSuccessEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showSuccessEffect = false
                // 正解したら回路をクリア(アニメーション付き)
                withAnimation(.easeOut(duration: 0.2)) {
                    circuitGates.removeAll()
                }
            }
        } else {
            showFailureEffect = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                showFailureEffect = false
            }
            // ゲームオーバーの場合はViewのonChangeで処理
        }
    }
    
    private func syncCircuitToViewModel() {
        // ローカルの回路状態をViewModelに同期
        viewModel.clearCircuit()
        for gate in circuitGates {
            viewModel.addGate(gate)
        }
    }
}

// MARK: - Effect Overlay

struct EffectOverlayView: UIViewRepresentable {
    @Binding var showSuccess: Bool
    @Binding var showFailure: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if showSuccess {
            CircuitAnimator.showSuccessEffect(on: uiView)
            CircuitAnimator.showStarsEffect(on: uiView)
        }
        if showFailure {
            CircuitAnimator.showFailureEffect(on: uiView)
        }
    }
}

#Preview("ゲーム画面", traits: .landscapeLeft) {
    GameView(difficulty: .easy, onGameEnd: { _ in })
}

