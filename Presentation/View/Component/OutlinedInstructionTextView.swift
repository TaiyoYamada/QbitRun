import SwiftUI
import UIKit

struct OutlinedInstructionTextView: UIViewRepresentable {
    let attributedText: AttributedString
    let baseFontSize: CGFloat
    let lineSpacing: CGFloat
    private let highlightedFontSizeDelta: CGFloat = 2
    private let highlightedStrokeWidth: CGFloat = -1.0

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = makeAttributedString()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        guard let width = proposal.width else {
            return uiView.intrinsicContentSize
        }
        uiView.preferredMaxLayoutWidth = width
        let fittingSize = uiView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: ceil(fittingSize.height))
    }

    private func makeAttributedString() -> NSAttributedString {
        let text = String(attributedText.characters)
        let result = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center

        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.7)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = CGSize(width: 0, height: 1)

        result.addAttributes([
            .font: UIFont.monospacedSystemFont(ofSize: baseFontSize, weight: .medium),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle,
            .shadow: shadow
        ], range: fullRange)

        let characters = attributedText.characters
        for run in attributedText.runs {
            guard let style = run[TutorialInstructionHighlightStyleAttribute.self] else { continue }

            let location = characters.distance(from: characters.startIndex, to: run.range.lowerBound)
            let length = characters.distance(from: run.range.lowerBound, to: run.range.upperBound)
            guard length > 0 else { continue }
            let nsRange = NSRange(location: location, length: length)

            result.addAttributes([
                .font: UIFont.monospacedSystemFont(
                    ofSize: baseFontSize + highlightedFontSizeDelta,
                    weight: .medium
                ),
                .foregroundColor: UIColor(TutorialInstructionStylePalette.frontColor(for: style)),
                .strokeColor: TutorialInstructionStylePalette.outlineUIColor(for: style),
                .strokeWidth: highlightedStrokeWidth
            ], range: nsRange)
        }

        return result
    }
}
