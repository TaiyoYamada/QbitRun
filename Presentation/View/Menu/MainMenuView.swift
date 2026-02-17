
import SwiftUI

struct MainMenuView: View {

    let onSelectMode: (GameDifficulty, Bool, Bool) -> Void
    let audioManager: AudioManager

    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var showTutorialConfirmation = false
    @State private var showSettings = false
    @State private var isNavigating = false

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

                VStack {
                    HStack(spacing: 20) {
                        Spacer()

                        if hasCompletedTutorial {
                            Button(action: {
                                audioManager.playSFX(.button)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showTutorialConfirmation = true
                                }
                            }) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            .padding(.top, 40)
                        }

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

                if showSettings {
                    SettingsView(
                        audioManager: audioManager,
                        onDismiss: {
                            audioManager.playSFX(.cancel)
                            withAnimation(.easeOut(duration: 0.2)) {
                                showSettings = false
                            }
                        }
                    )
                    .zIndex(100)
                    .transition(.opacity)
                }

                if showTutorialConfirmation {
                    TutorialConfirmationView(
                        onConfirm: {
                            startTutorial()
                            showTutorialConfirmation = false
                        },
                        onCancel: {
                            audioManager.playSFX(.cancel)
                            showTutorialConfirmation = false
                        }
                    )
                    .zIndex(100)
                    .transition(.opacity)
                }

            }
        }
        .onAppear {
            isNavigating = false
            audioManager.playBGM(.menu)
        }

    }

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
                .font(.system(size: 190, weight: .bold, design: .rounded))
                .tracking(10)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white.opacity(0.95), .cyan.opacity(0.95), .purple.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 35)

            Text("Run")
                .font(.system(size: 135, weight: .light, design: .rounded))
                .tracking(10)
                .foregroundStyle(.white.opacity(0.9))
        }
    }

    private var menuButtons: some View {
        VStack(spacing: 24) {
            QuantumModeCard(
                title: "EASY MODE",
                subtitle: "Start from |0⟩",
                icon: "arrow.up",
                accentColor: .white,
                isRandomStart: false,
                action: {
                    if hasCompletedTutorial {
                        triggerTransition(difficulty: .easy)
                    } else {
                        startForcedTutorial(targetDifficulty: .easy)
                    }
                }
            )

            QuantumModeCard(
                title: "HARD MODE",
                subtitle: "Random Start",
                icon: "shuffle",
                accentColor: .cyan,
                isRandomStart: true,
                action: {
                    if hasCompletedTutorial {
                        triggerTransition(difficulty: .hard)
                    } else {
                        startForcedTutorial(targetDifficulty: .hard)
                    }
                }
            )

            QuantumModeCard(
                title: "EXPERT MODE",
                subtitle: "Advanced States",
                icon: "atom",
                accentColor: .purple,
                isRandomStart: true,
                action: {
                    if hasCompletedTutorial {
                        triggerTransition(difficulty: .expert)
                    } else {
                        startForcedTutorial(targetDifficulty: .expert)
                    }
                }
            )
        }
        .frame(width: 450)
    }

    private func triggerTransition(difficulty: GameDifficulty) {
        if isNavigating { return }
        isNavigating = true

        audioManager.playSFX(.click)
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()

        Task {
            try? await Task.sleep(for: .milliseconds(150))

            let isTutorial = (difficulty == .easy && !hasCompletedTutorial)
            onSelectMode(difficulty, isTutorial, false)
        }
    }

    private func startTutorial() {
        if isNavigating { return }
        isNavigating = true

        audioManager.playSFX(.click)
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()

        Task {
            try? await Task.sleep(for: .milliseconds(150))
            // for review mode (from ? button), isTutorial=true, isReview=true
            onSelectMode(.easy, true, true)
        }
    }

    private func startForcedTutorial(targetDifficulty: GameDifficulty) {
        if isNavigating { return }
        isNavigating = true

        audioManager.playSFX(.click)
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()

        Task {
            try? await Task.sleep(for: .milliseconds(150))
            onSelectMode(targetDifficulty, true, false)
        }
    }

}

#Preview("New Main Menu") {
    MainMenuView(
        onSelectMode: { _, _, _ in },
        audioManager: AudioManager()
    )
}
