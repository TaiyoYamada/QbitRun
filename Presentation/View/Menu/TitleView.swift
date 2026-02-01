import SwiftUI
import simd

struct TitleView: View {
    
    /// メニュー画面へ遷移するコールバック
    let onStart: () -> Void
    
    /// 4つの角のアニメーション角度（それぞれ異なる動き）
    @State private var angles: [Double] = [0, 0.8, 1.6, 2.4]
    
    /// ボタンボーダーの回転角度
    @State private var borderRotation: Double = 0
    
    /// 各ブロッホ球の回転速度（ランダム）
    private let speeds: [Double] = [0.018, 0.025, 0.022, 0.015]
    
    /// 各ブロッホ球の緯度変化係数
    private let thetaFactors: [Double] = [0.3, 0.5, 0.2, 0.4]
    
    /// 指定インデックスの状態ベクトル
    private func vectorFor(index: Int) -> BlochVector {
        let theta = angles[index] * thetaFactors[index]
        let phi = angles[index]
        
        let x = sin(theta) * cos(phi)
        let y = sin(theta) * sin(phi)
        let z = cos(theta)
        
        return BlochVector(simd_double3(x, y, z))
    }
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            // 背景グラデーション
            Color.black.ignoresSafeArea()
            
            // 四隅にブロッホ球を配置
            VStack {
                HStack {
                    cornerBlochSphere(index: 0)
                    Spacer()
                    cornerBlochSphere(index: 1)
                }
                Spacer()
                HStack {
                    cornerBlochSphere(index: 2)
                    Spacer()
                    cornerBlochSphere(index: 3)
                }
            }
            .padding(20)
            
            // メインコンテンツ
            VStack(spacing: 0) {
                Spacer()
                
                // タイトル
                Text("Quantum Gate")
                    .font(.custom("Optima-Bold", size: 100))
                    .foregroundStyle(.white)
                
                // サブタイトル
                Text("Master the Bloch Sphere")
                    .font(.custom("Optima-Bold", size: 40))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 8)
                
                // スタートボタン（回転するグラデーションボーダー）
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onStart()
                }) {
                    Text("Start")
                        .font(.custom("Optima-Bold", size: 50))
                        .foregroundStyle(.white)
                        .frame(width: 250, height: 80)
                        .background(
                            // グラスモーフィズム背景
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.15))
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.ultraThinMaterial)
                                )
                        )
                        .overlay(
                            // 回転するグラデーションボーダー
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            .white.opacity(0.8),
                                            .white.opacity(0.1),
                                            .white.opacity(0.0),
                                            .white.opacity(0.1),
                                            .white.opacity(0.8)
                                        ]),
                                        center: .center,
                                        angle: .degrees(borderRotation)
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .white.opacity(0.15), radius: 15, x: 0, y: 5)
                }
                .buttonStyle(.glass)
                .padding(.top, 48)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        borderRotation = 360
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    @ViewBuilder
    private func cornerBlochSphere(index: Int) -> some View {
        BlochSphereViewRepresentable(
            vector: vectorFor(index: index),
            animated: false,
            showBackground: false,
            showAxes: false
        )
        .frame(width: 270, height: 270)
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [self] _ in
            Task { @MainActor in
                for i in 0..<4 {
                    angles[i] += speeds[i]
                }
            }
        }
    }
}

/// ボタンのスケールアニメーション
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview("タイトル画面") {
    TitleView(onStart: { print("Start tapped") })
}

