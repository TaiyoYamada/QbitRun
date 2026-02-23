import SwiftUI

enum PostTutorialGuideTarget: Hashable {
    case sphere
    case gatePalette
    case circuitSlot
    case scoreAndTime
    case centerStart

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

struct PostTutorialGuideTargetLayout {
    let arrowPoint: CGPoint
    let panelPoint: CGPoint
    let arrowRotation: Angle
    let arrowTravel: CGSize
    let showsArrow: Bool
}

struct PostTutorialGuideTuning {
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
        ),
        .centerStart: PostTutorialGuideTuning(
            anchorRatio: CGPoint(x: 0.50, y: 0.50),
            arrowOffset: .zero,
            panelOffset: .zero,
            arrowRotation: .degrees(0),
            arrowTravel: .zero,
            showsArrow: false
        )
    ]
}
