import SwiftUI

extension TutorialStep {

    private struct InstructionHighlightRule {
        let pattern: String
        let style: TutorialInstructionHighlightStyle
    }

    private static let instructionHighlightRules: [InstructionHighlightRule] = [
        InstructionHighlightRule(pattern: "(X+Z) axis", style: .xzAxis),
        InstructionHighlightRule(pattern: "the X-axis", style: .xAxis),
        InstructionHighlightRule(pattern: "the Y-axis", style: .yAxis),
        InstructionHighlightRule(pattern: "the Z-axis", style: .zAxis),
        InstructionHighlightRule(pattern: "X-axis", style: .xAxis),
        InstructionHighlightRule(pattern: "Y-axis", style: .yAxis),
        InstructionHighlightRule(pattern: "Z-axis", style: .zAxis),
        InstructionHighlightRule(pattern: "The arrow", style: .arrow),
    ]

    func attributedInstruction(isReviewMode: Bool) -> AttributedString {
        let raw = instruction(isReviewMode: isReviewMode)
        var result = AttributedString(raw)

        for rule in Self.instructionHighlightRules {
            var searchRange = result.startIndex..<result.endIndex
            while let range = result[searchRange].range(of: rule.pattern) {
                result[range].foregroundColor = TutorialInstructionStylePalette.frontColor(for: rule.style)
                result[range].inlinePresentationIntent = .stronglyEmphasized
                result[range][TutorialInstructionHighlightStyleAttribute.self] = rule.style
                if range.upperBound < result.endIndex {
                    searchRange = range.upperBound..<result.endIndex
                } else {
                    break
                }
            }
        }

        return result
    }
}
