import SwiftUI
import simd

struct MenuView: View {
    
    /// ゲーム開始時のコールバック
    let onStartGame: () -> Void
    
    /// スコアリポジトリ
    let scoreRepository: ScoreRepository
    
    /// 4つの角のアニメーション角度（それぞれ異なる動き）
    @State private var angles: [Double] = [0, 0.8, 1.6, 2.4]
    
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
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.05, green: 0.1, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 四隅にブロッホ球を配置
            VStack {
                HStack {
                    // 左上
                    cornerBlochSphere(index: 0)
                    Spacer()
                    // 右上
                    cornerBlochSphere(index: 1)
                }
                Spacer()
                HStack {
                    // 左下
                    cornerBlochSphere(index: 2)
                    Spacer()
                    // 右下
                    cornerBlochSphere(index: 3)
                }
            }
            .padding(20)
            
            // メインコンテンツ
            VStack(spacing: 0) {
                Spacer()
                
                // タイトル
                Text("Quantum Gate")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                
                // サブタイトル
                Text("Master the Bloch Sphere")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 8)
                
                // スタートボタン
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onStartGame()
                }) {
                    Text("Start Game")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 200, height: 56)
                        .background(Color(red: 0.4, green: 0.2, blue: 0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 48)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    /// 角に表示するブロッホ球
    @ViewBuilder
    private func cornerBlochSphere(index: Int) -> some View {
        BlochSphereViewRepresentable(vector: vectorFor(index: index), animated: false)
            .frame(width: 250, height: 250)
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            for i in 0..<4 {
                angles[i] += speeds[i]
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

#Preview("メニュー画面") {
    MenuView(
        onStartGame: { print("Start tapped") },
        scoreRepository: ScoreRepository()
    )
}
