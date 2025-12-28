// SPDX-License-Identifier: MIT
// Presentation/Game/GameView.swift
// ゲーム画面（SwiftUI版）

import SwiftUI

/// ゲーム画面
struct GameView: View {
    
    /// ViewModel
    @State private var viewModel = GameViewModel()
    
    /// ゲーム終了時のコールバック
    let onGameEnd: (ScoreEntry) -> Void
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // タイマーとスコア
                headerSection
                
                // ブロッホ球表示エリア
                spheresSection
                
                // 距離ゲージ
                DistanceGaugeViewRepresentable(distance: viewModel.distance)
                    .frame(width: 200, height: 24)
                    .padding(.top, 16)
                
                // 回路表示エリア
                circuitSection
                
                Spacer()
                
                // ゲートパレット
                GatePaletteViewRepresentable { gate in
                    viewModel.addGate(gate)
                }
                .frame(height: 76)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onChange(of: viewModel.finalScore) { _, newScore in
            if let score = newScore {
                onGameEnd(score)
            }
        }
    }
    
    // MARK: - ヘッダー（タイマー＆スコア）
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            // タイマー
            Text(String(format: "%02d", viewModel.remainingTime))
                .font(.system(size: 32, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(viewModel.isTimeLow ? Color.red : .white)
            
            // スコア
            Text("\(viewModel.score) pts • \(viewModel.problemsSolved) solved")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(red: 0.6, green: 0.4, blue: 1.0))
        }
        .padding(.top, 16)
    }
    
    // MARK: - ブロッホ球表示
    
    private var spheresSection: some View {
        HStack(spacing: 20) {
            // 現在の状態
            VStack(spacing: 4) {
                BlochSphereViewRepresentable(
                    vector: viewModel.currentVector,
                    animated: true
                )
                .frame(width: 150, height: 150)
                
                Text("Current")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // 矢印
            Text("→")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
            
            // ターゲット状態
            VStack(spacing: 4) {
                BlochSphereViewRepresentable(
                    vector: viewModel.targetVector,
                    animated: true
                )
                .frame(width: 150, height: 150)
                
                Text("Target")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - 回路表示
    
    private var circuitSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // クリアボタン
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                viewModel.clearCircuit()
            }) {
                Text("Clear")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // 回路ビュー
            CircuitViewRepresentable(
                gates: viewModel.circuit,
                onGateReceived: { gate in
                    viewModel.addGate(gate)
                },
                onGateRemoved: { index in
                    viewModel.removeGate(at: index)
                }
            )
            .frame(height: 72)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
    }
}

// MARK: - UIViewRepresentable ラッパー

/// CircuitView の SwiftUI ラッパー
struct CircuitViewRepresentable: UIViewRepresentable {
    let gates: [QuantumGate]
    let onGateReceived: (QuantumGate) -> Void
    let onGateRemoved: (Int) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onGateReceived: onGateReceived, onGateRemoved: onGateRemoved)
    }
    
    func makeUIView(context: Context) -> CircuitView {
        let view = CircuitView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: CircuitView, context: Context) {
        uiView.updateCircuit(gates)
    }
    
    class Coordinator: NSObject, CircuitViewDelegate {
        let onGateReceived: (QuantumGate) -> Void
        let onGateRemoved: (Int) -> Void
        
        init(onGateReceived: @escaping (QuantumGate) -> Void, onGateRemoved: @escaping (Int) -> Void) {
            self.onGateReceived = onGateReceived
            self.onGateRemoved = onGateRemoved
        }
        
        func circuitView(_ view: CircuitView, didReceiveGate gate: QuantumGate) {
            onGateReceived(gate)
        }
        
        func circuitView(_ view: CircuitView, didRemoveGateAt index: Int) {
            onGateRemoved(index)
        }
    }
}

/// GatePaletteView の SwiftUI ラッパー
struct GatePaletteViewRepresentable: UIViewRepresentable {
    let onGateSelected: (QuantumGate) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onGateSelected: onGateSelected)
    }
    
    func makeUIView(context: Context) -> GatePaletteView {
        let view = GatePaletteView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: GatePaletteView, context: Context) {
        // 更新処理は不要
    }
    
    class Coordinator: NSObject, GatePaletteViewDelegate {
        let onGateSelected: (QuantumGate) -> Void
        
        init(onGateSelected: @escaping (QuantumGate) -> Void) {
            self.onGateSelected = onGateSelected
        }
        
        func gatePalette(_ palette: GatePaletteView, didSelectGate gate: QuantumGate) {
            onGateSelected(gate)
        }
    }
}

/// DistanceGaugeView の SwiftUI ラッパー
struct DistanceGaugeViewRepresentable: UIViewRepresentable {
    let distance: Double
    
    func makeUIView(context: Context) -> DistanceGaugeView {
        DistanceGaugeView()
    }
    
    func updateUIView(_ uiView: DistanceGaugeView, context: Context) {
        uiView.setDistance(distance)
    }
}

// MARK: - プレビュー

#Preview("ゲーム画面") {
    GameView(onGameEnd: { _ in })
}
