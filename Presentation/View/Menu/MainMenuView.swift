// SPDX-License-Identifier: MIT
// Presentation/View/Menu/MainMenuView.swift

import SwiftUI

/// メインメニュー画面（Refined Quantum Style）
struct MainMenuView: View {

    // MARK: - Actions
    let onSelectMode: (GameDifficulty) -> Void
    let audioManager: AudioManager // [NEW]

    // MARK: - State
    @State private var shimmerOffset: CGFloat = -200
    @State private var showSettings = false // [NEW]
    @State private var isNavigating = false // [NEW] Prevent double tap

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                settingsLayer

                PositionedBlochSphere(geometry: geometry)

                HStack {
                    VStack(alignment: .leading, spacing: 100) {
                        Spacer()
                        
                        headerView
                            .offset(y: -geometry.size.height * 0.05)

                        menuButtons
                            .offset(y: geometry.size.height * 0.03)

                        Spacer()
                    }
                    .padding(.leading, geometry.size.width * 0.05)
                    Spacer()
                }
                
                // Settings Button (Top Right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            audioManager.playSFX(.button)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSettings = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.top, 40)
                        .padding(.trailing, 40)
                    }
                    Spacer()
                }
                
                // Settings Overlay
                if showSettings {
                    SettingsView(
                        audioManager: audioManager,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showSettings = false
                            }
                        }
                    )
                    .zIndex(100)
                    .transition(.opacity)
                }

            }
        }
        .onAppear {
            isNavigating = false // Reset navigation state
            audioManager.playBGM(.menu)
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
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.18), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 300)

                Spacer()
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.18), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(height: 300)
            }
            .ignoresSafeArea()
        }
    }

    private func PositionedBlochSphere(geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * 1.5

        return BlochSphereViewRepresentable(
            vector: BlochVector.plus,
            animated: false,
            showBackground: false,
            showAxes: true,
            showAxisLabels: false,
            continuousOrbitAnimation: true,
            axisOpacity: 0.3
        )
        .frame(width: size, height: size)
        .position(
            x: geometry.size.width * 0.7,
            y: geometry.size.height * 0.5
        )
        .opacity(0.8)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Qbit")
                .font(.system(size: 160, weight: .bold, design: .rounded))
                .tracking(7)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cyan.opacity(0.6), radius: 30, x: 0, y: 0)

            Text("Play")
                .font(.system(size: 115, weight: .thin, design: .rounded))
                .tracking(7)
                .foregroundStyle(.white.opacity(0.8))
        }
//        .onAppear {
//            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
//                shimmerOffset = 400
//            }
//        }
    }

    private var menuButtons: some View {
        VStack(spacing: 24) {
            QuantumModeCard(
                title: "EASY MODE",
                subtitle: "Start from |0⟩",
                icon: "arrow.up",
                accentColor: .white,
                isRandomStart: false,
                action: { triggerTransition(difficulty: .easy) }
            )
            
            QuantumModeCard(
                title: "HARD MODE",
                subtitle: "Random Start",
                icon: "questionmark",
                accentColor: .cyan,
                isRandomStart: true,
                action: { triggerTransition(difficulty: .hard) }
            )
            
            QuantumModeCard(
                title: "EXPERT MODE",
                subtitle: "Advanced States",
                icon: "sparkles",
                accentColor: .purple,
                isRandomStart: true,
                action: { triggerTransition(difficulty: .expert) }
            )
        }
        .frame(width: 450)
    }

    // MARK: - Logic
    private func triggerTransition(difficulty: GameDifficulty) {
        if isNavigating { return } // Prevent double tap
        isNavigating = true
        
        audioManager.playSFX(.click) // [NEW]
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
        
        // Buttons handle their own press animation, so just delay the action slightly
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            onSelectMode(difficulty)
        }
    }



}

#Preview("New Main Menu") {
    MainMenuView(
        onSelectMode: { _ in },
        audioManager: AudioManager()
    )
}
