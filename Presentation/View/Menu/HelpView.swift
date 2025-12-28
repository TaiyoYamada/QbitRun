import SwiftUI

/// アプリの使い方画面
struct HelpView: View {
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // ヘッダー
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                        
                        Text("How to Play")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.clear)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        HelpSection(
                            icon: "🎯",
                            title: "Goal",
                            description: "Transform the quantum state |0⟩ to match the target state shown on the Bloch sphere."
                        )
                        
                        HelpSection(
                            icon: "🎮",
                            title: "Controls",
                            description: "Drag quantum gates from the palette and drop them onto the circuit to apply transformations."
                        )
                        
                        HelpSection(
                            icon: "⏱️",
                            title: "Time Limit",
                            description: "You have 60 seconds to solve as many problems as possible. Each correct solution earns points!"
                        )
                        
                        HelpSection(
                            icon: "🔮",
                            title: "Quantum Gates",
                            description: """
                            • X Gate: Flips the state (like a NOT gate)
                            • Y Gate: Rotation around Y-axis
                            • Z Gate: Phase flip
                            • H Gate: Creates superposition
                            • S Gate: π/2 phase gate
                            • T Gate: π/4 phase gate
                            """
                        )
                        
                        HelpSection(
                            icon: "💡",
                            title: "Tips",
                            description: "The closer your state to the target, the faster it will be recognized as correct. Practice makes perfect!"
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

struct HelpSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text(description)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("使い方画面") {
    HelpView(onBack: { print("Back") })
}
