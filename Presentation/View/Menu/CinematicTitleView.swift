// SPDX-License-Identifier: MIT
// Presentation/View/Menu/CinematicTitleView.swift
// 映画のような導入アニメーション付きタイトル画面

import SwiftUI
import simd

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Cinematic Title Screen（案B: 回路とブロッホ球の統合）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// アニメーションフロー:
//
// 0秒: バイナリレイン開始 + ブロッホ球が中央に出現
// 0.5秒: 量子回路が右→左へ流れる（2秒間）
//        ゲートが球を通過するたびに状態ベクトルが回転
// 2.5秒: 回路消失、「タップしてXゲートを適用」
// タップ: ベクトルが南極へ移動
// → メインメニューへ遷移
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// アニメーションフェーズ
private enum TitlePhase: Equatable {
    case initial         // 初期状態
    case circuitFlow     // 量子回路アニメーション中
    case waitingTap      // タップ待ち
    case applyingGate    // Xゲート適用中
    case transition      // メニューへ遷移
}

/// シネマティックタイトルView
struct CinematicTitleView: View {
    
    /// メニュー画面への遷移コールバック
    let onStart: () -> Void
    
    // MARK: - State
    
    @State private var phase: TitlePhase = .initial
    @State private var blochVector: BlochVector = .zero
    @State private var showBlochSphere: Bool = false
    @State private var showTapPrompt: Bool = false
    @State private var promptOpacity: Double = 1.0
    @State private var showGateSymbol: Bool = false
    @State private var orbitActive: Bool = true  // 軌道アニメーション有効
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（純黒）
                Color.black.ignoresSafeArea()
                
                // Layer 1: バイナリレイン
                BinaryRainRepresentable(
                    phase: phase,
                    size: geometry.size
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()
                
                // Layer 2: 量子回路アニメーション
                if phase == .circuitFlow {
                    QuantumCircuitRepresentable(
                        size: geometry.size,
                        onComplete: {
                            withAnimation {
                                phase = .waitingTap
                                showTapPrompt = true
                            }
                            startPromptPulse()
                        }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
                
                // Layer 3: ブロッホ球（最前面、軸あり・ラベルなし、滑らかな軌道アニメーション）
                if showBlochSphere {
                    BlochSphereViewRepresentable(
                        vector: blochVector,
                        animated: true,
                        showBackground: false,
                        showAxes: true,
                        showAxisLabels: false,
                        continuousOrbitAnimation: orbitActive  // 滑らかな軌道アニメーション
                    )
                    .frame(width: 500, height: 500)
                    .scaleEffect(showBlochSphere ? 1.0 : 0.3)
                    .opacity(showBlochSphere ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showBlochSphere)
                    .zIndex(100)  // 最前面に表示
                }
                
                // Layer 4: タップ促進UI
                if showTapPrompt && phase == .waitingTap {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 24))
                            Text("Tap to apply X gate")
                                .font(.custom("Optima-Bold", size: 24))
                        }
                        .foregroundColor(.white)
                        .opacity(promptOpacity)
                        .padding(.bottom, 100)
                    }
                }
                
                // Layer 5: Xゲートシンボル
                if showGateSymbol {
                    xGateSymbolView
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onTapGesture {
            handleTap()
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    // MARK: - Xゲートシンボル
    
    private var xGateSymbolView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .frame(width: 80, height: 80)
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyan, lineWidth: 3)
                .frame(width: 80, height: 80)
            
            Text("X")
                .font(.custom("Menlo-Bold", size: 48))
                .foregroundColor(.white)
        }
        .shadow(color: .cyan.opacity(0.6), radius: 20)
    }
    
    // MARK: - Animation Sequence
    
    private func startAnimationSequence() {
        // ブロッホ球を即座に表示（軌道アニメーションは自動的に開始）
        showBlochSphere = true
        
        // 0.5秒後に回路アニメーション開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            phase = .circuitFlow
        }
    }
    
    private func startPromptPulse() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            promptOpacity = 0.4
        }
    }
    
    private func handleTap() {
        guard phase == .waitingTap else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        phase = .applyingGate
        showTapPrompt = false
        
        // 軌道アニメーションを停止
        orbitActive = false
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showGateSymbol = true
        }
        
        // Xゲートで|1⟩に移動
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            blochVector = BlochVector(simd_double3(0, 0, -1))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showGateSymbol = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            phase = .transition
            onStart()
        }
    }
}

// MARK: - Binary Rain Representable

private struct BinaryRainRepresentable: UIViewRepresentable {
    let phase: TitlePhase
    let size: CGSize
    
    func makeUIView(context: Context) -> BinaryRainContainerView {
        let container = BinaryRainContainerView()
        container.backgroundColor = .clear
        return container
    }
    
    func updateUIView(_ uiView: BinaryRainContainerView, context: Context) {
        guard size.width > 0 && size.height > 0 else { return }
        
        if !context.coordinator.hasStartedRain {
            context.coordinator.hasStartedRain = true
            uiView.startRain(size: size)
        }
        
        if phase == .waitingTap && !context.coordinator.hasFadedRain {
            context.coordinator.hasFadedRain = true
            uiView.fadeOutRain()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hasStartedRain = false
        var hasFadedRain = false
    }
}

private class BinaryRainContainerView: UIView {
    private var rainLayer: BinaryRainLayer?
    
    func startRain(size: CGSize) {
        rainLayer?.removeFromSuperlayer()
        
        let newRainLayer = BinaryRainLayer()
        newRainLayer.frame = CGRect(origin: .zero, size: size)
        layer.addSublayer(newRainLayer)
        rainLayer = newRainLayer
        
        newRainLayer.startRain(in: size)
    }
    
    func fadeOutRain() {
        rainLayer?.fadeOut(duration: 1.5)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        rainLayer?.frame = bounds
    }
}

// MARK: - Quantum Circuit Representable

private struct QuantumCircuitRepresentable: UIViewRepresentable {
    let size: CGSize
    let onComplete: () -> Void
    
    func makeUIView(context: Context) -> QuantumCircuitAnimationView {
        let view = QuantumCircuitAnimationView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: QuantumCircuitAnimationView, context: Context) {
        guard size.width > 0 && size.height > 0 else { return }
        guard !context.coordinator.hasStarted else { return }
        
        context.coordinator.hasStarted = true
        
        uiView.frame = CGRect(origin: .zero, size: size)
        uiView.onAnimationComplete = onComplete
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            uiView.startAnimation(duration: 2.0)  // 2秒
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hasStarted = false
    }
}

// MARK: - Preview

#Preview("Cinematic Title") {
    CinematicTitleView(onStart: { print("Start!") })
}
