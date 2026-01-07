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
            // 背景グラデーション
            // 背景グラデーション
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // タイマーとスコア
                headerSection
                
                // ブロッホ球表示エリア
                spheresSection
                
                // 回路表示エリア
                circuitSection
                
                Spacer()
                
                // ゲートパレット（タップで追加）
                SwiftUIGatePaletteView { gate in
                    if circuitGates.count < 5 {
                        circuitGates.append(gate)
                        viewModel.addGate(gate)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            
            // 成功/失敗エフェクト用オーバーレイ
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
    
    // MARK: - ヘッダー
    
    private var headerSection: some View {
        HStack {
            // お手つき残り（ハート）
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < viewModel.remainingMisses ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundStyle(index < viewModel.remainingMisses ? Color.red : Color.gray.opacity(0.4))
                }
            }
            
            Spacer()
            
            // タイマー
            Text(String(format: "%02d", viewModel.remainingTime))
                .font(.system(size: 60, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(viewModel.isTimeLow ? Color.red : .white)
            
            Spacer()
            
            // スコア
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.score) pts")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
                
                Text("\(viewModel.problemsSolved) solved")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - ブロッホ球表示
    
    private var spheresSection: some View {
        HStack(spacing: 50) {
            // 現在の状態
            VStack(spacing: 4) {
                BlochSphereViewRepresentable(
                    vector: viewModel.currentVector,
                    animated: true
                )
                .frame(width: 350, height: 350)

                Text("Current")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // 矢印
            Image(systemName: "arrow.right")
                .font(.system(size: 60, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
            
            // ターゲット状態
            VStack(spacing: 4) {
                BlochSphereViewRepresentable(
                    vector: viewModel.targetVector,
                    animated: true
                )
                .frame(width: 350, height: 350)

                Text("Target")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - 回路表示
    
    private var circuitSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // クリアボタン
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                circuitGates.removeAll()
                viewModel.clearCircuit()
            }) {
                Text("Clear")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // 回路ビュー（SwiftUIネイティブD&D）
            SwiftUICircuitView(
                gates: $circuitGates,
                onRun: { runCircuit() }
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
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
                // 正解したら回路をクリア
                circuitGates.removeAll()
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
