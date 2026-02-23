import SwiftUI

struct PostTutorialGuideOverlayView: View {
    let step: PostTutorialGuideStep
    let onNextTapped: () -> Void

    @State private var activeTargetIndex = 0
    @State private var targetCycleTask: Task<Void, Never>?

    private var currentTarget: PostTutorialGuideTarget {
        let targets = step.targets
        guard !targets.isEmpty else { return .sphere }
        let safeIndex = min(activeTargetIndex, targets.count - 1)
        return targets[safeIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = currentTarget.layout(in: geometry.size)

            ZStack {
                Color.black.opacity(0.50)
                    .ignoresSafeArea()

                if layout.showsArrow {
                    GuideArrowView(layout: layout)
                        .position(layout.arrowPoint)
                        .id(currentTarget)
                }

                guidePanel
                    .frame(width: min(550, geometry.size.width * 0.75))
                    .position(layout.panelPoint)
            }
            .animation(.easeInOut(duration: 0.26), value: currentTarget)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Game guide")
            .accessibilityHint("Read this quick guide and move to the next step.")
        }
        .onAppear {
            configureTargetCycle()
        }
        .onChange(of: step) { _, _ in
            configureTargetCycle()
        }
        .onDisappear {
            stopTargetCycle()
        }
    }

    private var guidePanel: some View {
        VStack(alignment: .center, spacing: 50) {
            Text(step.message)
                .font(.system(size: 27, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .tracking(1)
                .multilineTextAlignment(.leading)
                .lineSpacing(5)
                .frame(alignment: .center)

            Button(action: onNextTapped) {
                Text(step.buttonTitle)
                    .font(.system(size: 37, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 90)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(0.72))
                            .overlay {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.cyan.opacity(0.65),
                                                Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.75)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .opacity(0.85)
                            }
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.75), lineWidth: 3)
                    )
                    .shadow(color: .cyan.opacity(0.4), radius: 10)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.buttonTitle == "START" ? "Start game" : "Next guide step")
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    private func configureTargetCycle() {
        stopTargetCycle()
        activeTargetIndex = 0

        guard step.targets.count > 1 else { return }

        targetCycleTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1600))
                if Task.isCancelled { return }

                withAnimation(.easeInOut(duration: 0.26)) {
                    activeTargetIndex = (activeTargetIndex + 1) % step.targets.count
                }
            }
        }
    }

    private func stopTargetCycle() {
        targetCycleTask?.cancel()
        targetCycleTask = nil
    }
}

#Preview("Post Tutorial Guide - Step 1") {
    ZStack {
        Color.black
        PostTutorialGuideOverlayView(step: .matchTargetVector, onNextTapped: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Post Tutorial Guide - Step 2") {
    ZStack {
        Color.black
        PostTutorialGuideOverlayView(step: .buildCircuitAndRun, onNextTapped: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Post Tutorial Guide - Step 3") {
    ZStack {
        Color.black
        PostTutorialGuideOverlayView(step: .scoreAndTime, onNextTapped: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Post Tutorial Guide - Step 4") {
    ZStack {
        Color.black
        PostTutorialGuideOverlayView(step: .readyToStart, onNextTapped: {})
    }
    .preferredColorScheme(.dark)
}
