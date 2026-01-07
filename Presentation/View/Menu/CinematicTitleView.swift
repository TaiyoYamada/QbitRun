import SwiftUI
import simd

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

    @State private var orbitActive: Bool = true  // 軌道アニメーション有効
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（純黒）
                Color.black.ignoresSafeArea()



                // Layer 2: 量子回路アニメーション（背景ループ）
                // 常に表示、最背面に配置（Color.blackの上、ブロッホ球の下）
                QuantumCircuitRepresentable(
                    size: geometry.size
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()
                .opacity(0.8) // 全体の透明度を少し下げる（内部でさらに0.3になる）

                // Layer 3: ブロッホ球（最前面、軸あり・ラベルなし、滑らかな軌道アニメーション）
                if showBlochSphere {
                    BlochSphereViewRepresentable(
                        vector: blochVector,
                        animated: true,
                        showBackground: false,
                        showAxes: true,
                        showAxisLabels: false,
                        continuousOrbitAnimation: orbitActive,  // 滑らかな軌道アニメーション
                        onOrbitStop: { finalVector in
                            // 軌道停止時に観測を行う
                            measureQuantumState(from: finalVector)
                        }
                    )
                    .frame(width: 500, height: 550)
                    .scaleEffect(showBlochSphere ? 1.0 : 0.3)
                    .opacity(showBlochSphere ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showBlochSphere)
                    .zIndex(100)
                }

                // Layer 4: タップ促進UI
                if showTapPrompt && phase == .waitingTap {
                    VStack {
                        Spacer()
                        Text("Tap to Measure Quantum State")
                            .font(.custom("Optima-Bold", size: 40))
                    }
                    .foregroundColor(.white)
                    .opacity(promptOpacity)
                    .padding(.bottom, 100)
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
    

    
    // MARK: - Animation Sequence
    
    private func startAnimationSequence() {
        // ブロッホ球を即座に表示（軌道アニメーションは自動的に開始）
        showBlochSphere = true
        
        // 少し待ってからタップ待ち状態へフェードイン
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                phase = .waitingTap
                showTapPrompt = true
            }
            startPromptPulse()
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
        
        // 軌道アニメーションを停止（これによりonOrbitStopが呼ばれ、measureQuantumStateが実行される）
        orbitActive = false
        
        // メニュー遷移
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            phase = .transition
            onStart()
        }
    }
    
    /// 量子状態の観測（測定）
    /// 現在のベクトルから、近い方の基底状態（|0⟩または|1⟩）に収束させる
    private func measureQuantumState(from vector: BlochVector) {
        // ベクトルのZ成分を確認（Z軸が量子化軸）
        let z = vector.vector.z
        
        // Z > 0 なら |0⟩ (北極)、Z <= 0 なら |1⟩ (南極) に収束
        // 確率的には cos(theta/2)^2 だが、ここでは「近い方」というユーザー要望により距離判定
        let measuredState: BlochVector
        if z > 0 {
            measuredState = .zero // |0⟩
        } else {
            measuredState = BlochVector(simd_double3(0, 0, -1)) // |1⟩
        }
        
        // アニメーションで収束させる
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.blochVector = measuredState
            }
        }
    }
}



// MARK: - Quantum Circuit Representable



// MARK: - Preview

#Preview("Cinematic Title") {
    CinematicTitleView(onStart: { print("Start!") })
}
