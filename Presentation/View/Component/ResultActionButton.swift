import SwiftUI
import UIKit

// MARK: - リザルトアクションボタン

/// Result画面専用のアクションボタン
struct ResultActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let isProminent: Bool
    
    init(title: String, icon: String, color: Color, isProminent: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isProminent = isProminent
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Label(title, systemImage: icon)
                .font(.appButton)
        }
        .tint(color)
    }
}
