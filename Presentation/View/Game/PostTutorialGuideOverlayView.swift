import SwiftUI

enum PostTutorialGuideStep: Int, CaseIterable, Sendable {
    case matchTargetVector
    case buildCircuitAndRun
    case scoreAndTime

    var message: String {
        switch self {
        case .matchTargetVector:
            return """
            Rotate the red vector to align
            with the white target.
            When they match, it turns gold.
            """
        case .buildCircuitAndRun:
            return """
            Pick gates from the palette.
            Build your circuit, then tap Run.
            """
        case .scoreAndTime:
            return """
            Score increases with each solve.
            Chain solves for bonus points.
            Keep an eye on the timer.
            """
        }
    }

    var buttonTitle: String {
        self == .scoreAndTime ? "START" : "NEXT"
    }

    fileprivate var targets: [PostTutorialGuideTarget] {
        switch self {
        case .matchTargetVector:
            return [.sphere]
        case .buildCircuitAndRun:
            return [.gatePalette]
        case .scoreAndTime:
            return [.scoreAndTime]
        }
    }
}

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

private enum PostTutorialGuideTarget: Hashable {
    case sphere
    case gatePalette
    case circuitSlot
    case scoreAndTime

    func layout(in containerSize: CGSize) -> PostTutorialGuideTargetLayout {
        let tuning = PostTutorialGuideTuning.configuration[self] ?? .fallback
        let anchor = CGPoint(
            x: containerSize.width * tuning.anchorRatio.x,
            y: containerSize.height * tuning.anchorRatio.y
        )

        return PostTutorialGuideTargetLayout(
            arrowPoint: CGPoint(
                x: anchor.x + tuning.arrowOffset.width,
                y: anchor.y + tuning.arrowOffset.height
            ),
            panelPoint: CGPoint(
                x: anchor.x + tuning.panelOffset.width,
                y: anchor.y + tuning.panelOffset.height
            ),
            arrowRotation: tuning.arrowRotation,
            arrowTravel: tuning.arrowTravel,
            showsArrow: tuning.showsArrow
        )
    }
}

private struct PostTutorialGuideTargetLayout {
    let arrowPoint: CGPoint
    let panelPoint: CGPoint
    let arrowRotation: Angle
    let arrowTravel: CGSize
    let showsArrow: Bool
}

private struct PostTutorialGuideTuning {
    let anchorRatio: CGPoint
    let arrowOffset: CGSize
    let panelOffset: CGSize
    let arrowRotation: Angle
    let arrowTravel: CGSize
    let showsArrow: Bool

    static let fallback = PostTutorialGuideTuning(
        anchorRatio: CGPoint(x: 0.5, y: 0.5),
        arrowOffset: CGSize(width: 0, height: 120),
        panelOffset: CGSize(width: 0, height: 240),
        arrowRotation: .degrees(0),
        arrowTravel: CGSize(width: 0, height: -24),
        showsArrow: true
    )

    static let configuration: [PostTutorialGuideTarget: PostTutorialGuideTuning] = [
        .sphere: PostTutorialGuideTuning(
            anchorRatio: CGPoint(x: 0.50, y: 0.80),
            arrowOffset: CGSize(width: 0, height: -100),
            panelOffset: CGSize(width: 0, height: 60),
            arrowRotation: .degrees(0),
            arrowTravel: CGSize(width: 80, height: -200),
            showsArrow: false
        ),
        .gatePalette: PostTutorialGuideTuning(
            anchorRatio: CGPoint(x: 0.50, y: 0.90),
            arrowOffset: CGSize(width: 0, height: -180),
            panelOffset: CGSize(width: 0, height: -410),
            arrowRotation: .degrees(180),
            arrowTravel: CGSize(width: 0, height: 24),
            showsArrow: true
        ),
        .scoreAndTime: PostTutorialGuideTuning(
            anchorRatio: CGPoint(x: 0.50, y: 0.12),
            arrowOffset: CGSize(width: -110, height: 70),
            panelOffset: CGSize(width: -110, height: 290),
            arrowRotation: .degrees(0),
            arrowTravel: CGSize(width: 0, height: -24),
            showsArrow: true
        )
    ]
}

private struct GuideArrowView: View {
    let layout: PostTutorialGuideTargetLayout

    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "arrowshape.up.fill")
            .font(.system(size: 74, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        .white,
                        Color(red: 0.65, green: 0.95, blue: 1.0),
                        Color(red: 0.35, green: 0.50, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .white.opacity(0.45), radius: 10)
            .rotationEffect(layout.arrowRotation)
            .offset(
                x: isAnimating ? 0 : -layout.arrowTravel.width,
                y: isAnimating ? 0 : -layout.arrowTravel.height
            )
            .opacity(isAnimating ? 1 : 0)
            .onAppear {
                isAnimating = false
                withAnimation(.easeOut(duration: 0.95).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview("Post Tutorial Guide - Step 1") {
    ZStack {
        UnifiedBackgroundView()
        PostTutorialGuideOverlayView(step: .matchTargetVector, onNextTapped: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Post Tutorial Guide - Step 2") {
    ZStack {
        UnifiedBackgroundView()
        PostTutorialGuideOverlayView(step: .buildCircuitAndRun, onNextTapped: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Post Tutorial Guide - Step 3") {
    ZStack {
        UnifiedBackgroundView()
        PostTutorialGuideOverlayView(step: .scoreAndTime, onNextTapped: {})
    }
    .preferredColorScheme(.dark)
}
