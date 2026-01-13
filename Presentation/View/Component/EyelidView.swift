import SwiftUI

/// 目の開口部（アパーチャ）の形状
private struct EyeApertureShape: Shape {
    /// 目の開き具合 (0.0: 完全に閉じている 〜 1.0: 完全に開いている)
    var openness: CGFloat
    
    // アニメーション対応
    var animatableData: CGFloat {
        get { openness }
        set { openness = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerY = height / 2
        
        // 開き具合に応じた目の高さ（最大で画面高さより大きくして完全に視界確保）
        let eyeHeight = height * 1.5 * openness
        
        // 左端からスタート (0, centerY)
        path.move(to: CGPoint(x: 0, y: centerY))
        
        // 上まぶたのカーブ
        path.addQuadCurve(
            to: CGPoint(x: width, y: centerY),
            control: CGPoint(x: width / 2, y: centerY - eyeHeight)
        )
        
        // 下まぶたのカーブ
        path.addQuadCurve(
            to: CGPoint(x: 0, y: centerY),
            control: CGPoint(x: width / 2, y: centerY + eyeHeight)
        )
        
        path.closeSubpath()
        return path
    }
}

/// まぶたの動きをシミュレートするビュー
/// 画面全体を覆い、中央から目の形に開くアニメーションを行う
struct EyelidView: View {
    
    // MARK: - Properties
    
    /// 目が開いているかどうか
    let isOpen: Bool
    
    /// アニメーション時間
    var duration: Double = 0.8
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 背景（黒い幕）
            Rectangle()
                .fill(Color.black)
            
            // 目の形にくり抜く（DestinationOut合成）
            EyeApertureShape(openness: isOpen ? 1.0 : 0.0)
                .fill(Color.black)
                .blendMode(.destinationOut)
        }
        .compositingGroup() // これがないとBlendModeが背景色まで透過してしまう
        .shadow(color: .black, radius: 20, x: 0, y: 0) // 穴の境界に影を落とす（EyelidShape側ではなく全体にかかるが、穴の縁にも効果あるか確認）
        // ShadowはCompositingGroupの後にかけるとView全体の影になる。
        // 穴の縁に影を落とすには、穴が開いた黒い板に影をつける必要がある。
        // destinationOutした結果（穴あき板）に対してshadowをつける。
        .ignoresSafeArea()
        .animation(.easeInOut(duration: duration), value: isOpen)
    }
}

#Preview("Open") {
    ZStack {
        Color.blue.ignoresSafeArea()
        Text("Hello Quantum World")
            .font(.largeTitle)
            .foregroundColor(.white)
        EyelidView(isOpen: true)
    }
}

#Preview("Closed") {
    ZStack {
        Color.blue.ignoresSafeArea()
        Text("Hello Quantum World")
            .font(.largeTitle)
            .foregroundColor(.white)
        EyelidView(isOpen: false)
    }
}

#Preview("Transition") {
    struct PreviewWrapper: View {
        @State var isOpen = false
        var body: some View {
            ZStack {
                Color.cyan.ignoresSafeArea()
                Text("Blink Test")
                    .font(.largeTitle)
                EyelidView(isOpen: isOpen)
                
                VStack {
                    Spacer()
                    Button("Toggle") {
                        isOpen.toggle()
                    }
                    .padding()
                    .background(.white)
                    .clipShape(Capsule())
                }
            }
        }
    }
    return PreviewWrapper()
}
