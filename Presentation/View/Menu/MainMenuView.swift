// SPDX-License-Identifier: MIT
// Presentation/View/Menu/MainMenuView.swift

import SwiftUI

/// メインメニュー画面（Refined Quantum Style）
struct MainMenuView: View {

    // MARK: - Actions
    let onSelectMode: (GameDifficulty) -> Void

    // MARK: - State
    @State private var shimmerOffset: CGFloat = -200

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

            }
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
            vector: BlochVector.plus,
            animated: false,
            showBackground: false,
            showAxes: true,
            showAxisLabels: false,
            continuousOrbitAnimation: true
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
            Text("QUANTUM")
                .font(.system(size: 90, weight: .thin, design: .rounded))
                .tracking(4)
                .foregroundStyle(.white.opacity(0.8))
            
            Text("GATE")
                .font(.system(size: 130, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 20, x: 0, y: 0)
//                .overlay {
//                    // Shine Effect
//                    GeometryReader { geo in
//                        Rectangle()
//                            .fill(
//                                LinearGradient(
//                                    colors: [.clear, .white.opacity(0.5), .clear],
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                )
//                            )
//                            .rotationEffect(.degrees(20))
//                            .offset(x: shimmerOffset)
//                            .mask(
//                                Text("GATE")
//                                    .font(.system(size: 120, weight: .bold, design: .rounded))
//                                    .tracking(2)
//                            )
//                    }
//                    .frame(width: 300, height: 100)
//                }
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }

    private var menuButtons: some View {
        VStack(spacing: 24) {
            QuantumModeCard(
                title: "EASY MODE",
                subtitle: "Start from |0⟩",
                icon: "arrow.up",
                accentColor: .cyan,
                isRandomStart: false,
                action: { triggerTransition(difficulty: .easy) }
            )
            
            QuantumModeCard(
                title: "HARD MODE",
                subtitle: "Random Start",
                icon: "questionmark",
                accentColor: .purple,
                isRandomStart: true,
                action: { triggerTransition(difficulty: .hard) }
            )
        }
        .frame(width: 450)
    }

    // MARK: - Logic
    private func triggerTransition(difficulty: GameDifficulty) {
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
        onSelectMode: { _ in }
    )
}
