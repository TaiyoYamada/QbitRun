import Foundation

enum TutorialInstructionHighlightStyle: String, Sendable, Hashable {
    case xAxis
    case yAxis
    case zAxis
    case xzAxis
    case arrow
}

struct TutorialInstructionHighlightStyleAttribute: AttributedStringKey {
    typealias Value = TutorialInstructionHighlightStyle
    static let name = "tutorialInstructionHighlightStyle"
}
