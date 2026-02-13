import SwiftUI

/// メインメニュー画面（Quantum Cockpit Style - Advanced）
struct MainMenuView: View {

    // MARK: - Actions
    let onSelectMode: (GameDifficulty) -> Void

    // MARK: - State
    @State private var showContent = false
    @State private var backgroundVector = BlochVector.plus
    @State private var rotationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settingsLayer

                // 右下に大きく配置
                PositionedBlochSphere(geometry: geometry)

                // Layer 3: Main UI
                HStack {
                    VStack(alignment: .leading, spacing: 30) {
                        headerView

                        Spacer()
                            .frame(height: 50)

                        menuButtons

                    }
                    .padding(.leading, 60)
//                    .frame(width: geometry.size.width * 0.5)

                    Spacer()
                }
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -50)
            }
        }
        .task {
            await startAppearanceAnimation()
            await startBackgroundRotation()
        }
        .onDisappear {
            rotationTask?.cancel()
        }
    }

    // MARK: - Subviews

    private var settingsLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            QuantumCircuitRepresentable(size: CGSize(width: 1000, height: 1000))
                .ignoresSafeArea()
                .opacity(0.4)

            VStack {
                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.2), .clear],
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
        let size = min(geometry.size.width, geometry.size.height) * 1.5

        return BlochSphereViewRepresentable(
            vector: backgroundVector,
            animated: true,
            showBackground: false,
            showAxes: true,
            showAxisLabels: false,
            continuousOrbitAnimation: false
        )
        .frame(width: size, height: size)
        .position(
            x: geometry.size.width * 0.7,
            y: geometry.size.height * 0.45
        )
        .opacity(0.8)
        .blur(radius: 1)
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
        VStack(alignment: .leading, spacing: 32) {
            MenuButtonCard(
                title: "Easy Mode",
                subtitle: GameDifficulty.easy.description,
                icon: "leaf.fill",
                color: .cyan,
                action: { triggerTransition(action: { onSelectMode(.easy) }) }
            )

            MenuButtonCard(
                title: "Hard Mode",
                subtitle: GameDifficulty.hard.description,
                icon: "flame.fill",
                color: .orange,
                action: { triggerTransition(action: { onSelectMode(.hard) }) }
            )
        }
    }

    // MARK: - Logic
    private func triggerTransition(action: @escaping () -> Void) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        action()
    }

    private func startAppearanceAnimation() async {
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
    }

    private func startBackgroundRotation() async {
        var angle: Double = 0
        while !Task.isCancelled {
            angle += 0.02
            let y = sin(angle)
            let z = cos(angle)
            backgroundVector = BlochVector(x: 0, y: y, z: z)
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
}

// MARK: - Advanced Components

struct MenuButtonCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 24) {
                // Icon Box with Rotating Ornament
                ZStack {
                    // 背景の回転するリング
                    Circle()
                        .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 8]))
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .frame(width: 64, height: 64)

                    // メインアイコンボックス
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(color.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(color.opacity(0.5), lineWidth: 1)
                            )

                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundStyle(color)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                    .frame(width: 52, height: 52)
                }
                .frame(width: 64, height: 64)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 26, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(color.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(QuantumButtonStyle(color: color))
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct QuantumButtonStyle: ButtonStyle {
    let color: Color
    @State private var scanPhase: Double = 0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                ZStack {
                    // ベースレイヤー（グラスエフェクト）
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .opacity(0.9)

                    // エネルギー充填グラデーション
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.1), color.opacity(0.02)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // エッジを走る光のスキャン
                    RoundedRectangle(cornerRadius: 14)
                        .trim(from: scanPhase, to: scanPhase + 0.15)
                        .stroke(color, lineWidth: 2)
                        .blur(radius: 1)
                }
            }
            .overlay {
                // 枠線（常時表示）
                RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: color.opacity(configuration.isPressed ? 0.6 : 0.2), radius: configuration.isPressed ? 15 : 5)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    scanPhase = 1.0
                }
            }
    }
}

#Preview("New Main Menu") {
    MainMenuView(
        onSelectMode: { _ in }
    )
}
