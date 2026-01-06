// SPDX-License-Identifier: MIT
// Presentation/Component/GlassButton.swift
// グラスモーフィズムスタイルのボタンコンポーネント

import SwiftUI

/// グラスモーフィズムボタン（回転するグラデーションボーダー）
struct GlassButton: View {
    let title: String
    let action: () -> Void
    
    /// ボタンのサイズ
    var width: CGFloat = 220
    var height: CGFloat = 60
    var fontSize: CGFloat = 24
    
    /// ボーダーアニメーションを有効にするか
    var animated: Bool = true
    
    @State private var borderRotation: Double = 0
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            Text(title)
                .font(.custom("Optima-Bold", size: fontSize))
                .foregroundStyle(.white)
                .frame(width: width, height: height)
                .background(
                    // グラスモーフィズム背景
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white.opacity(0.15))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                )
                .overlay(
                    // 回転するグラデーションボーダー
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.8),
                                    .white.opacity(0.1),
                                    .white.opacity(0.0),
                                    .white.opacity(0.1),
                                    .white.opacity(0.8)
                                ]),
                                center: .center,
                                angle: .degrees(borderRotation)
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .white.opacity(0.15), radius: 15, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            if animated {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    borderRotation = 360
                }
            }
        }
    }
}

/// 小型のグラスボタン（アイコン＋テキスト）
struct GlassIconButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var borderRotation: Double = 0
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.custom("Optima-Bold", size: 20))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview("GlassButton") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            GlassButton(title: "Start", action: {})
            GlassButton(title: "Records", action: {}, width: 180, height: 50, fontSize: 20)
            GlassIconButton(title: "Back", icon: "chevron.left", action: {})
        }
    }
}
