// SPDX-License-Identifier: MIT
// Presentation/View/Menu/MainMenuView.swift

import SwiftUI

/// メインメニュー画面（Refined Quantum Style）
struct MainMenuView: View {

    // MARK: - Actions
    let onSelectMode: (GameDifficulty) -> Void

    // MARK: - State
    @State private var showContent = false
    @State private var backgroundVector = BlochVector.plus
    @State private var rotationTask: Task<Void, Never>?
    @State private var titleOffset: CGFloat = -200

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Original Background
                settingsLayer

                // Layer 2: Floating Bloch Sphere (Right side / Background)
                PositionedBlochSphere(geometry: geometry)

                // Layer 3: Main UI (Modernized)
                HStack {
                    VStack(alignment: .leading, spacing: 40) {
                        Spacer()
                        
                        headerView
                        
                        menuButtons
                        
                        Spacer()
                    }
                    .padding(.leading, geometry.size.width * 0.08)
                    .frame(maxWidth: 500)
                    // Ensure content doesn't overlook safe area on left
                    
                    Spacer()
                }
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -30) // Gentle slide-in
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
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("QUANTUM")
                .font(.system(size: 40, weight: .thin, design: .rounded))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.8))
            
            Text("GATE")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 20, x: 0, y: 0)
                .overlay {
                    // Shine Effect
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.5), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .rotationEffect(.degrees(20))
                            .offset(x: titleOffset)
                            .mask(
                                Text("GATE")
                                    .font(.system(size: 80, weight: .bold, design: .rounded))
                                    .tracking(2)
                            )
                    }
                    .frame(width: 300, height: 100)
                }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                titleOffset = 400
            }
        }
    }

    private var menuButtons: some View {
        VStack(alignment: .leading, spacing: 24) {
            GlassMenuButton(
                title: "Easy Mode",
                subtitle: GameDifficulty.easy.description,
                icon: "leaf.fill",
                accentColor: .cyan, // Changed back to Cyan/Orange to match original theme slightly better
                action: { triggerTransition(difficulty: .easy) }
            )
            
            GlassMenuButton(
                title: "Hard Mode",
                subtitle: GameDifficulty.hard.description,
                icon: "flame.fill",
                accentColor: .orange,
                action: { triggerTransition(difficulty: .hard) }
            )
        }
    }

    // MARK: - Logic
    private func triggerTransition(difficulty: GameDifficulty) {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        
        // Buttons handle their own press animation, so just delay the action slightly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onSelectMode(difficulty)
        }
    }

    private func startAppearanceAnimation() async {
        // Reset title offset for animation loop
        titleOffset = -200
        
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

// MARK: - Components

struct GlassMenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 20) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(accentColor)
                        .symbolEffect(.bounce, value: isHovered)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial) // Glassmorphism
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: accentColor.opacity(isHovered ? 0.3 : 0), radius: 15, x: 0, y: 0)
            .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview("New Main Menu") {
    MainMenuView(
        onSelectMode: { _ in }
    )
}
