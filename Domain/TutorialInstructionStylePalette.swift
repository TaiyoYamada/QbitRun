import SwiftUI
import UIKit

enum TutorialInstructionStylePalette {
    static func frontColor(for style: TutorialInstructionHighlightStyle) -> Color {
        switch style {
        case .xAxis:
            return BlochAxisPalette.xAxisColor
        case .yAxis:
            return BlochAxisPalette.yAxisColor
        case .zAxis:
            return BlochAxisPalette.zAxisColor
        case .xzAxis:
            return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .arrow:
            return .red
        }
    }

    static func outlineUIColor(for style: TutorialInstructionHighlightStyle) -> UIColor {
        switch style {
        case .xAxis:
            return .white
        case .yAxis:
            return .cyan
        case .zAxis:
            return .cyan
        case .xzAxis:
            return .white
        case .arrow:
            return .systemPink
        }
    }
}
