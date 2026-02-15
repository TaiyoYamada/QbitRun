// SPDX-License-Identifier: MIT
// Presentation/View/Component/GateReferenceView.swift

import SwiftUI

/// ゲートの説明を表示するモーダルビュー
///
/// 責務:
/// - ゲーム内で使用される量子ゲートの効果を視覚的に説明する
/// - ユーザーがゲームのルールを理解するためのリファレンスとして機能する
struct GateReferenceView: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Introduction
                    Text("Quantum Gates manipulate the state of a qubit on the Bloch Sphere.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Gate List
                    VStack(spacing: 16) {
                        gateRow(gate: .x, description: "Rotates 180° around the X-axis.\n(Bit Flip: |0⟩ ↔ |1⟩)")
                        gateRow(gate: .y, description: "Rotates 180° around the Y-axis.\n(Bit & Phase Flip)")
                        gateRow(gate: .z, description: "Rotates 180° around the Z-axis.\n(Phase Flip: |+⟩ ↔ |-⟩)")
                        gateRow(gate: .h, description: "Hadamard Gate.\nCreates Superposition.\n|0⟩ → |+⟩, |1⟩ → |-⟩")
                        // S, T gate logic if added later
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Gate Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.gray.opacity(0.8))
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func gateRow(gate: QuantumGate, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Text(gate.symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(gate.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: gate.swiftUIColor.opacity(0.4), radius: 4, x: 0, y: 2)
            
            // Description
            VStack(alignment: .leading, spacing: 4) {
                Text(gate.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    GateReferenceView()
}
