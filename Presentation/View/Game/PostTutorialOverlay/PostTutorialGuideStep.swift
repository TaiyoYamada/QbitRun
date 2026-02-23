import Foundation

enum PostTutorialGuideStep: Int, CaseIterable, Sendable {
    case matchTargetVector
    case buildCircuitAndRun
    case scoreAndTime
    case readyToStart

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
        case .readyToStart:
            return """
            Are you ready?
            Tap START to begin the game!
            """
        }
    }

    var buttonTitle: String {
        self == .readyToStart ? "START" : "NEXT"
    }

    var targets: [PostTutorialGuideTarget] {
        switch self {
        case .matchTargetVector:
            return [.sphere]
        case .buildCircuitAndRun:
            return [.gatePalette]
        case .scoreAndTime:
            return [.scoreAndTime]
        case .readyToStart:
            return [.centerStart]
        }
    }
}
