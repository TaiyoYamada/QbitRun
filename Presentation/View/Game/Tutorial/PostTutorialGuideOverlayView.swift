import SwiftUI
import UIKit

struct PostTutorialGuideOverlayView: View {
    let step: PostTutorialGuideStep
    let focusFrames: [PostTutorialGuideTarget: CGRect]
    let onNextTapped: () -> Void

    @State private var activeTargetIndex = 0
    @State private var targetCycleTask: Task<Void, Never>?

    init(
        step: PostTutorialGuideStep,
        focusFrames: [PostTutorialGuideTarget: CGRect] = [:],
        onNextTapped: @escaping () -> Void
    ) {
        self.step = step
        self.focusFrames = focusFrames
        self.onNextTapped = onNextTapped
    }

    private var currentTarget: PostTutorialGuideTarget {
        let targets = step.targets
        guard !targets.isEmpty else { return .sphere }
        let safeIndex = min(activeTargetIndex, targets.count - 1)
        return targets[safeIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            let layout = currentTarget.layout(in: geometry.size)
            let cutout = currentTarget.cutout(in: geometry.size, focusFrames: focusFrames)

            ZStack {
                overlayBackground(cutout: cutout)

                if layout.showsArrow {
                    GuideArrowView(layout: layout)
                        .position(layout.arrowPoint)
                        .id(currentTarget)
                }

                guidePanel
                    .frame(width: min(550, geometry.size.width * 0.75))
                    .position(layout.panelPoint)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    ))
            }
            .animation(.easeInOut(duration: 0.35), value: currentTarget)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Game guide")
            .accessibilityHint("Read this quick guide and move to the next step.")
        }
        .onAppear {
            configureTargetCycle()
            announceCurrentStepForVoiceOver()
        }
        .onChange(of: step) { _, _ in
            configureTargetCycle()
            announceCurrentStepForVoiceOver()
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
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.9),
                                Color(red: 0.24, green: 0.36, blue: 0.82).opacity(0.9),
                                Color(red: 0.25, green: 0.08, blue: 0.48).opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(.white.opacity(0.6), lineWidth: 3)
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(step.buttonTitle == "START" ? "Start game" : "Next guide step")
            .accessibilityHint(step.buttonTitle == "START"
                ? "Start the timed game."
                : "Move to the next guide explanation.")
        }
        .padding(.horizontal, 50)
        .padding(.vertical, 40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.8),
                            Color(red: 0.24, green: 0.36, blue: 0.82).opacity(0.8),
                            Color(red: 0.25, green: 0.08, blue: 0.48).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 8)
    }

    private func overlayBackground(cutout: PostTutorialGuideCutout?) -> some View {
        ZStack {
            Color.black.opacity(0.75)

            if let cutout {
                RoundedRectangle(cornerRadius: cutout.cornerRadius, style: .continuous)
                    .frame(width: cutout.rect.width, height: cutout.rect.height)
                    .position(x: cutout.rect.midX, y: cutout.rect.midY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .ignoresSafeArea()
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

    private func announceCurrentStepForVoiceOver() {
        guard UIAccessibility.isVoiceOverRunning else { return }

        let message = step.message.replacingOccurrences(of: "\n", with: " ")
        UIAccessibility.post(notification: .screenChanged, argument: message)
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
