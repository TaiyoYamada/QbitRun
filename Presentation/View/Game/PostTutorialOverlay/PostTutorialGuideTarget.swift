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

    func cutout(in containerSize: CGSize, focusFrames: [PostTutorialGuideTarget: CGRect]) -> PostTutorialGuideCutout? {
        guard let tuning = PostTutorialGuideCutoutTuning.configuration[self] else { return nil }

        if let frame = focusFrames[self], !frame.isEmpty {
            let expanded = tuning.frameOutsets
                .apply(to: frame)
                .offsetBy(dx: tuning.frameOffset.width, dy: tuning.frameOffset.height)
            let clampedRadius = min(tuning.cornerRadius, min(expanded.width, expanded.height) / 2)
            return PostTutorialGuideCutout(rect: expanded, cornerRadius: clampedRadius)
        }

        return tuning.fallbackCutout(in: containerSize)
    }
}

struct PostTutorialGuideTargetLayout {
    let arrowPoint: CGPoint
    let panelPoint: CGPoint
    let arrowRotation: Angle
    let arrowTravel: CGSize
    let showsArrow: Bool
}

struct PostTutorialGuideCutout {
    let rect: CGRect
    let cornerRadius: CGFloat
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

struct PostTutorialGuideCutoutTuning {
    let frameOutsets: PostTutorialGuideRectOutsets
    let frameOffset: CGSize
    let fallbackAnchorRatio: CGPoint
    let fallbackOffset: CGSize
    let fallbackSizeRatio: CGSize
    let fallbackMaxSize: CGSize
    let cornerRadius: CGFloat

    func fallbackCutout(in containerSize: CGSize) -> PostTutorialGuideCutout {
        let width = min(containerSize.width * fallbackSizeRatio.width, fallbackMaxSize.width)
        let height = min(containerSize.height * fallbackSizeRatio.height, fallbackMaxSize.height)
        let center = CGPoint(
            x: containerSize.width * fallbackAnchorRatio.x + fallbackOffset.width,
            y: containerSize.height * fallbackAnchorRatio.y + fallbackOffset.height
        )
        let rect = CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )

        return PostTutorialGuideCutout(rect: rect, cornerRadius: cornerRadius)
    }

    static let configuration: [PostTutorialGuideTarget: PostTutorialGuideCutoutTuning] = [
        .sphere: PostTutorialGuideCutoutTuning(
            frameOutsets: .uniform(24),
            frameOffset: CGSize(width: 0, height: -8),
            fallbackAnchorRatio: CGPoint(x: 0.50, y: 0.46),
            fallbackOffset: CGSize(width: 0, height: -15),
            fallbackSizeRatio: CGSize(width: 0.72, height: 0.40),
            fallbackMaxSize: CGSize(width: 640, height: 520),
            cornerRadius: 10
        ),
        .gatePalette: PostTutorialGuideCutoutTuning(
            frameOutsets: PostTutorialGuideRectOutsets(top: 170, leading: 24, bottom: 30, trailing: 24),
            frameOffset: .zero,
            fallbackAnchorRatio: CGPoint(x: 0.50, y: 0.90),
            fallbackOffset: CGSize(width: 0, height: -95),
            fallbackSizeRatio: CGSize(width: 0.94, height: 0.22),
            fallbackMaxSize: CGSize(width: 920, height: 430),
            cornerRadius: 20
        ),
        .scoreAndTime: PostTutorialGuideCutoutTuning(
            frameOutsets: PostTutorialGuideRectOutsets(top: 18, leading: 24, bottom: 18, trailing: 24),
            frameOffset: CGSize(width: 26, height: 14),
            fallbackAnchorRatio: CGPoint(x: 0.33, y: 0.11),
            fallbackOffset: CGSize(width: 26, height: 14),
            fallbackSizeRatio: CGSize(width: 0.66, height: 0.19),
            fallbackMaxSize: CGSize(width: 620, height: 220),
            cornerRadius: 20
        )
    ]
}

struct PostTutorialGuideRectOutsets {
    let top: CGFloat
    let leading: CGFloat
    let bottom: CGFloat
    let trailing: CGFloat

    static func uniform(_ value: CGFloat) -> PostTutorialGuideRectOutsets {
        PostTutorialGuideRectOutsets(top: value, leading: value, bottom: value, trailing: value)
    }

    func apply(to rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX - leading,
            y: rect.minY - top,
            width: rect.width + leading + trailing,
            height: rect.height + top + bottom
        )
    }
}
