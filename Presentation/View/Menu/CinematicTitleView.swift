// SPDX-License-Identifier: MIT
// Presentation/View/Menu/CinematicTitleView.swift
// 映画のような導入アニメーション付きタイトル画面

import SwiftUI
import simd

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Cinematic Title Screen
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// アニメーションフロー:
//
// 0秒: バイナリレイン開始
// 1秒: 量子回路が右→左へ流れる
// 3秒: ブロッホ球が中央に生成
// 4秒: 「タップしてXゲートを適用」
// タップ: |0⟩ → |1⟩ 回転
// → メインメニューへ遷移
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// アニメーションフェーズ
private enum TitlePhase: Equatable {
    case binaryRain      // バイナリレイン開始
    case circuitFlow     // 量子回路アニメーション
    case blochAppear     // ブロッホ球生成
    case waitingTap      // タップ待ち
    case applyingGate    // Xゲート適用中
    case transition      // メニューへ遷移
}

/// シネマティックタイトルView
struct CinematicTitleView: View {
    
    /// メニュー画面への遷移コールバック
    let onStart: () -> Void
    
    // MARK: - State
    
    @State private var phase: TitlePhase = .binaryRain
    @State private var blochVector: BlochVector = .zero
    @State private var showBlochSphere: Bool = false
    @State private var showTapPrompt: Bool = false
    @State private var promptOpacity: Double = 1.0
    @State private var showGateSymbol: Bool = false
    
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
                if phase == .circuitFlow || phase == .blochAppear {
                    QuantumCircuitRepresentable(
                        startAnimation: phase == .circuitFlow,
                        size: geometry.size,
                        onComplete: {
                            withAnimation(.easeOut(duration: 0.5)) {
                                phase = .blochAppear
                                showBlochSphere = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                phase = .waitingTap
                                showTapPrompt = true
                                startPromptPulse()
                            }
                        }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                }
                
                // Layer 3: ブロッホ球
                if showBlochSphere {
                    VStack {
                        Spacer()
                        
                        Text(blochVector == .zero ? "|0⟩" : "|1⟩")
                            .font(.custom("Menlo-Bold", size: 32))
                            .foregroundColor(.white)
                            .shadow(color: .cyan.opacity(0.8), radius: 10)
                        
                        BlochSphereViewRepresentable(
                            vector: blochVector,
                            animated: true,
                            showBackground: false,
                            showAxes: true
                        )
                        .frame(width: 350, height: 350)
                        .scaleEffect(showBlochSphere ? 1.0 : 0.3)
                        .opacity(showBlochSphere ? 1.0 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showBlochSphere)
                        
                        Spacer()
                    }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showGateSymbol = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                blochVector = BlochVector(simd_double3(0, 0, -1))
            }
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
        // サイズが有効な場合のみ処理
        guard size.width > 0 && size.height > 0 else { return }
        
        // レイン開始
        if !context.coordinator.hasStartedRain {
            context.coordinator.hasStartedRain = true
            uiView.startRain(size: size)
        }
        
        // フェードアウト
        if phase == .circuitFlow && !context.coordinator.hasFadedRain {
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

/// バイナリレインのコンテナView（レイアウトを正しく処理）
private class BinaryRainContainerView: UIView {
    private var rainLayer: BinaryRainLayer?
    
    func startRain(size: CGSize) {
        // 既存のレイヤーを削除
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
    let startAnimation: Bool
    let size: CGSize
    let onComplete: () -> Void
    
    func makeUIView(context: Context) -> QuantumCircuitAnimationView {
        let view = QuantumCircuitAnimationView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: QuantumCircuitAnimationView, context: Context) {
        // サイズが有効な場合のみ処理
        guard size.width > 0 && size.height > 0 else { return }
        guard startAnimation && !context.coordinator.hasStarted else { return }
        
        context.coordinator.hasStarted = true
        
        // フレームを明示的に設定
        uiView.frame = CGRect(origin: .zero, size: size)
        uiView.onAnimationComplete = onComplete
        
        // 少し遅延してアニメーション開始（レイアウト完了を待つ）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            uiView.startAnimation()  // デフォルト8秒
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
