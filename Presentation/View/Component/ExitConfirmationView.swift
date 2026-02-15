// SPDX-License-Identifier: MIT
// Presentation/View/Component/ExitConfirmationView.swift

import SwiftUI

/// カスタム終了確認モーダル
/// ゲームの「量子」の世界観に合わせたデザイン
struct ExitConfirmationView: View {
    
    // MARK: - Properties
    let title: String
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var animateIn = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateIn = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onCancel()
                    }
                }
            
            // Modal Content
            VStack(spacing: 40) {
                // Text
                VStack(spacing: 10) {
                    Text(title)
                        .font(.system(size: 43, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.5), radius: 3)

                    Text(message)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Buttons
                HStack(spacing: 25) {
                    // Cancel Button
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            animateIn = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onCancel()
                        }
                    }) {
                        Text("CANCEL")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(.white.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(.white.opacity(0.3), lineWidth: 3)
                            )
                    }
                    
                    // Exit Button (Destructive)
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        onConfirm()
                    }) {
                        Text("EXIT GAME")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.cyan.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(.white.opacity(0.6), lineWidth: 3)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .padding(30)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .frame(maxWidth: 520)
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    ExitConfirmationView(
        title: "END GAME?",
        message: "Current progress will be lost.",
        onConfirm: {},
        onCancel: {}
    )
}
