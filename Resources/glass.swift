//
//  glass.swift
//  QuantumGateGame
//
//  Created by 山田大陽 on 2026/01/31.
//

import SwiftUI

struct LiquidGlassTestView: View {
    var body: some View {
        GlassEffectContainer {
            ZStack {

                Color.black

                Image("background")  // 背景画像
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Text("Liquid Glass Test")
                        .font(.largeTitle)
                        .glassEffect(.regular)

                    Button("Click Me") {
                        print("Tapped")
                    }
                    .glassEffect(.clear)
                    .padding()
//                    .cornerRadius(12)
                }
                .padding()
            }
        }
    }
}

#Preview {
    LiquidGlassTestView()
}
