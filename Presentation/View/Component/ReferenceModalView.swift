// SPDX-License-Identifier: MIT
// Presentation/View/Component/ReferenceModalView.swift

import SwiftUI

struct ReferenceModalView: View {
    
    // MARK: - Properties
    var onDismiss: () -> Void
    
    @State private var animateIn = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal Content
            VStack(spacing: 20) {
                // Header
                Text("GATE REFERENCE")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .white.opacity(0.5), radius: 3)
                    .padding(.top, 25)
                
                // Content (Grid Layout)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    gateRow(gate: .x, name: "Pauli-X", description: "Bit Flip\n|0⟩ ↔ |1⟩")
                    gateRow(gate: .y, name: "Pauli-Y", description: "Bit & Phase Flip\n180° Y-Rot")
                    gateRow(gate: .z, name: "Pauli-Z", description: "Phase Flip\n|1⟩ → -|1⟩")
                    gateRow(gate: .h, name: "Hadamard", description: "Superposition\n|0⟩ → |+⟩")
                    gateRow(gate: .s, name: "Phase (S)", description: "90° Phase Shift\n√Z Gate")
                    gateRow(gate: .t, name: "T Gate", description: "45° Phase Shift\n√S Gate")
                }
                .padding(.horizontal)
                
                // Footer (Close Button)
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismissModal()
                }) {
                    Text("CLOSE")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(.white.opacity(0.3), lineWidth: 2)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 25)
            }
            .background(.thinMaterial) // Glassmorphism
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .frame(maxWidth: 550)
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0.0)
            .padding(20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func dismissModal() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func gateRow(gate: QuantumGate, name: String, description: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon
            Text(gate.symbol)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(gate.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: gate.swiftUIColor.opacity(0.5), radius: 3, x: 0, y: 2)
            
            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(height: 80) // Fixed height for uniformity
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ZStack {
        // Background for preview context
        Color.blue.opacity(0.3).ignoresSafeArea()
        
        ReferenceModalView(onDismiss: {})
    }
}
