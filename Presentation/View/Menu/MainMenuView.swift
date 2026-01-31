import SwiftUI

/// メインメニュー画面（Quantum Cockpit Style）
struct MainMenuView: View {
    
    // MARK: - Actions
    
    let onPlayGame: () -> Void
    let onShowRecords: () -> Void
    let onShowHelp: () -> Void
    
    // MARK: - State
    
    @State private var particleTrigger: UUID?
    @State private var nextAction: (() -> Void)?
    @State private var showContent = false
    @State private var isEyesOpen = false // 初期は閉じている
    @State private var showBlinkEffect = true
    
    // 背景のブロッホ球用ベクトル（自転アニメーションさせる）
    @State private var backgroundVector = BlochVector.plus
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Deep Background
                settingsLayer
                
                // Layer 2: 3D Object (Background Planet)
                // 右下に大きく配置
                PositionedBlochSphere(geometry: geometry)
                
                // Layer 3: Main UI
                HStack {
                    VStack(alignment: .leading, spacing: 30) {
                        // Header
                        headerView
                        
                        Spacer()
                            .frame(height: 20)
                        
                        // Menu Items
                        menuButtons
                        
                        Spacer()
                    }
                    .padding(.leading, 60)
                    .frame(width: geometry.size.width * 0.5) // 左半分を使う
                    
                    Spacer()
                }
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -50)
                
                // Layer 4: まぶた（Blink Effect）
                if showBlinkEffect {
                    EyelidView(isOpen: isEyesOpen)
                        .zIndex(200)
                        .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            // 少し遅れて目を開く
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isEyesOpen = true
                }
                // アニメーション完了後にViewを削除
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showBlinkEffect = false
                }
            }
            startBackgroundRotation()
        }
    }
    
    // MARK: - Subviews
    
    private var settingsLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 背景回路（薄く表示）
            QuantumCircuitRepresentable(size: CGSize(width: 1000, height: 1000))
                .ignoresSafeArea()
                .opacity(0.3)
            
            // グリッド装飾（未来的演出）
            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.1), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 200)
            }
            .ignoresSafeArea()
        }
    }
    
    private func PositionedBlochSphere(geometry: GeometryProxy) -> some View {
        // 画面右下、少しはみ出すくらいに配置
        let size = min(geometry.size.width, geometry.size.height) * 1.2
        
        return BlochSphereViewRepresentable(
            vector: backgroundVector,
            animated: true,
            showBackground: false,
            showAxes: true,
            showAxisLabels: false,
            continuousOrbitAnimation: false // 自転は自前で制御
        )
        .frame(width: size, height: size)
        .position(
            x: geometry.size.width * 0.75,
            y: geometry.size.height * 0.6
        )
        .opacity(0.8)
        .blur(radius: 1) // 遠近感を出すために少しぼかす
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("QUANTUM\nGATE")
                .font(.custom("Optima-Bold", size: 64))
                .foregroundStyle(.white)
                .lineSpacing(0)
                .shadow(color: .cyan.opacity(0.6), radius: 10, x: 0, y: 0)
            
            Rectangle()
                .fill(Color.cyan)
                .frame(width: 60, height: 4)
        }
    }
    
    private var menuButtons: some View {
        VStack(alignment: .leading, spacing: 24) {
            MenuButtonCard(
                title: "Initialize Game",
                subtitle: "Start a new quantum challenge",
                icon: "gamecontroller.fill",
                color: .cyan,
                action: { triggerTransition(action: onPlayGame) }
            )
            
            MenuButtonCard(
                title: "Flight Log",
                subtitle: "View your past records",
                icon: "list.bullet.rectangle.portrait.fill",
                color: .purple,
                action: { triggerTransition(action: onShowRecords) }
            )
            
            MenuButtonCard(
                title: "Manual",
                subtitle: "How to operate qubits",
                icon: "questionmark.circle.fill",
                color: .green,
                action: { triggerTransition(action: onShowHelp) }
            )
        }
    }
    
    // MARK: - Logic
    
    private func triggerTransition(action: @escaping () -> Void) {
        // 触感フィードバック
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // 直接アクション実行
        action()
    }
    
    /// 背景の惑星（ブロッホ球）をゆっくり自転させる
    private func startBackgroundRotation() {
        // ベクトルをゆっくり変化させたいが、
        // 単純なState更新だと再描画負荷が高い可能性がある。
        // BlochSphereView自体が内部でアニメーション補間を持っているので、
        // 定期的にターゲットを変えるアプローチをとる。
        
        Task { @MainActor in
            // 無限ループでベクトルを更新（軌道を描く）
            // X軸周りに回転させる例
            var angle: Double = 0
            while !Task.isCancelled {
                angle += 0.02
                let y = sin(angle)
                let z = cos(angle)
                
                // ブロッホ球の更新
                // （SwiftUIの描画更新サイクルに任せる）
                backgroundVector = BlochVector(x: 0, y: y, z: z)
                
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
}

// MARK: - Components

struct MenuButtonCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon Box
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                }
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .tracking(1)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .opacity(0.3)
            }
            .padding(16)
        }
        .buttonStyle(GlassButtonStyle())
        .tint(color)
    }
}

#Preview("New Main Menu") {
    MainMenuView(
        onPlayGame: {},
        onShowRecords: {},
        onShowHelp: {}
    )
}
