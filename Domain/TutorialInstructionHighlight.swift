import Foundation

/// チュートリアル説明文中のハイライトスタイルを表す列挙型
enum TutorialInstructionHighlightStyle: String, Sendable, Hashable {
    case xAxis
    case yAxis
    case zAxis
    case xzAxis
    case arrow
}

/// チュートリアル説明文にハイライトスタイルを付与するための`AttributedStringKey`
struct TutorialInstructionHighlightStyleAttribute: AttributedStringKey {
    typealias Value = TutorialInstructionHighlightStyle
    static let name = "tutorialInstructionHighlightStyle"
}
