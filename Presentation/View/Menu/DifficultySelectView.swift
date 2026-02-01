import SwiftUI

/// 難易度選択画面
struct DifficultySelectView: View {
    
    /// 難易度選択時のコールバック
    let onSelectDifficulty: (GameDifficulty) -> Void
    
    /// 戻るボタンのコールバック
    let onBack: () -> Void
    
    var body: some View {
        GlassEffectContainer {
            ZStack {
                // MARK: - Background
                backgroundLayer

                // MARK: - Main Content
                VStack(spacing: 0) {
                    // Header Area
                    HStack {
                        GlassIconButton(title: "Back", icon: "chevron.left", action: onBack)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("SELECT DIFFICULTY")
                            .font(.custom("Optima-Bold", size: 48))
                            .foregroundStyle(.white)
                            .shadow(color: .cyan.opacity(0.8), radius: 10, x: 0, y: 0)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .cyan, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 2)
                            .frame(width: 300)
                    }
                    
                    Spacer()
                    
                    // Difficulty Cards
                    HStack(spacing: 40) {
                        DifficultyCard(
                            difficulty: .easy,
                            color: .cyan,
                            description: "Standard quantum stability.\nRecommended for new pilots.",
                            action: { onSelectDifficulty(.easy) }
                        )
                        
                        DifficultyCard(
                            difficulty: .hard,
                            color: .orange,
                            description: "High quantum fluctuation.\nFor veteran pilots only.",
                            action: { onSelectDifficulty(.hard) }
                        )
                    }
                    .containerRelativeFrame(.horizontal) { length, axis in
                        length * 0.8
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
        }
    }
    private var backgroundLayer: some View {
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
}


// MARK: - Components

private struct DifficultyCard: View {
    let difficulty: GameDifficulty
    let color: Color
    let description: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background Glass
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)
                
                // Border & Glow
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                color.opacity(0.6),
                                color.opacity(0.1),
                                color.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: color.opacity(isHovering ? 0.6 : 0.2), radius: isHovering ? 20 : 10)
                
                // Content
                VStack(spacing: 20) {
                    // Emoji / Icon
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .blur(radius: 10)
                        
                        Text(difficulty.emoji)
                            .font(.system(size: 50))
                            .shadow(color: color.opacity(0.5), radius: 5)
                    }
                    
                    // Text Info
                    VStack(spacing: 12) {
                        Text(difficulty.displayName)
                            .font(.custom("Optima-Bold", size: 32))
                            .foregroundStyle(.white)
                        
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(30)
            }
            .frame(height: 300)
            .contentShape(Rectangle()) // Ensure tap area is solid
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(.plain) // Use plain style inside the wrapper to handle custom animation
        .onHover { mirroring in
            isHovering = mirroring
        }
    }
}

#Preview("難易度選択", traits: .landscapeLeft) {
    DifficultySelectView(
        onSelectDifficulty: { _ in },
        onBack: {}
    )
}
