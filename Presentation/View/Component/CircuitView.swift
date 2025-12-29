// SPDX-License-Identifier: MIT
// Presentation/Component/CircuitView.swift
// 量子回路ビュー（ワイヤーベースデザイン）

import UIKit
import UniformTypeIdentifiers

/// 回路ビューのイベントを通知するデリゲート
@MainActor
public protocol CircuitViewDelegate: AnyObject {
    func circuitView(_ view: CircuitView, didReceiveGate gate: QuantumGate)
    func circuitView(_ view: CircuitView, didRemoveGateAt index: Int)
}

/// 量子回路ビュー（ワイヤースタイル）
@MainActor
public final class CircuitView: UIView {
    
    // MARK: - 定数
    
    private let maxSlots = 5
    private let slotSize: CGFloat = 50
    private let wireHeight: CGFloat = 3
    
    // MARK: - プロパティ
    
    public weak var delegate: CircuitViewDelegate?
    private var gates: [QuantumGate] = []
    private var slotViews: [UIView] = []
    
    /// ワイヤーレイヤー
    private let wireLayer = CAShapeLayer()
    
    /// |0⟩ラベル
    private let initialStateLabel: UILabel = {
        let label = UILabel()
        label.text = "|0⟩"
        label.font = UIFont(name: "Menlo-Bold", size: 18) ?? UIFont.monospacedSystemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// Runボタン
    private lazy var runButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("▶ Run", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        return button
    }()
    
    /// スロットコンテナ
    private lazy var slotsContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - 初期化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI構築
    
    private func setupView() {
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        layer.cornerRadius = 12
        
        // ワイヤーレイヤー追加
        wireLayer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        wireLayer.lineWidth = wireHeight
        wireLayer.fillColor = nil
        layer.addSublayer(wireLayer)
        
        // UIをセットアップ
        addSubview(initialStateLabel)
        addSubview(slotsContainer)
        addSubview(runButton)
        
        // スロット作成
        for _ in 0..<maxSlots {
            let slot = createSlot()
            slotViews.append(slot)
            slotsContainer.addArrangedSubview(slot)
        }
        
        NSLayoutConstraint.activate([
            // |0⟩ラベル
            initialStateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            initialStateLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // スロットコンテナ
            slotsContainer.leadingAnchor.constraint(equalTo: initialStateLabel.trailingAnchor, constant: 20),
            slotsContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Runボタン
            runButton.leadingAnchor.constraint(equalTo: slotsContainer.trailingAnchor, constant: 20),
            runButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            runButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            runButton.widthAnchor.constraint(equalToConstant: 80),
            runButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // ドロップ機能
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
    }
    
    private func createSlot() -> UIView {
        let slot = UIView()
        slot.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        slot.layer.cornerRadius = 8
        slot.layer.borderWidth = 2
        slot.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        slot.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            slot.widthAnchor.constraint(equalToConstant: slotSize),
            slot.heightAnchor.constraint(equalToConstant: slotSize)
        ])
        
        return slot
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        updateWire()
    }
    
    /// ワイヤーを描画
    private func updateWire() {
        let path = UIBezierPath()
        
        let y = bounds.midY
        let startX = initialStateLabel.frame.maxX + 8
        let endX = runButton.frame.minX - 8
        
        path.move(to: CGPoint(x: startX, y: y))
        path.addLine(to: CGPoint(x: endX, y: y))
        
        wireLayer.path = path.cgPath
    }
    
    // MARK: - 公開メソッド
    
    public func updateCircuit(_ gates: [QuantumGate]) {
        self.gates = gates
        
        for (index, slot) in slotViews.enumerated() {
            slot.subviews.forEach { $0.removeFromSuperview() }
            
            if index < gates.count {
                let gate = gates[index]
                let label = UILabel()
                label.text = gate.symbol
                label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
                label.textColor = .white
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                
                slot.addSubview(label)
                slot.backgroundColor = gate.color.withAlphaComponent(0.9)
                slot.layer.borderColor = gate.color.cgColor
                
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: slot.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: slot.centerYAnchor)
                ])
                
                setupTapToRemove(for: slot, at: index)
            } else {
                slot.backgroundColor = UIColor.white.withAlphaComponent(0.08)
                slot.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
                slot.gestureRecognizers?.forEach { slot.removeGestureRecognizer($0) }
            }
        }
        
        // Runボタンの状態更新
        runButton.isEnabled = !gates.isEmpty
        runButton.alpha = gates.isEmpty ? 0.5 : 1.0
    }
    
    private func setupTapToRemove(for slot: UIView, at index: Int) {
        slot.gestureRecognizers?.forEach { slot.removeGestureRecognizer($0) }
        let tap = UITapGestureRecognizer(target: self, action: #selector(slotTapped(_:)))
        slot.addGestureRecognizer(tap)
        slot.tag = index
        slot.isUserInteractionEnabled = true
    }
    
    @objc private func slotTapped(_ gesture: UITapGestureRecognizer) {
        guard let slot = gesture.view else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        delegate?.circuitView(self, didRemoveGateAt: slot.tag)
    }
    
    @objc private func runTapped() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        // Note: SwiftUICircuitViewを使用しているため、ここでは何もしない
    }
    
    // MARK: - アニメーション
    
    /// ゲートを順番に光らせる
    public func animateGateSequence(completion: @escaping () -> Void) {
        guard !gates.isEmpty else {
            completion()
            return
        }
        
        let duration: TimeInterval = 0.2
        
        for (index, slot) in slotViews.enumerated() {
            guard index < gates.count else { continue }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * Double(index)) {
                // 光るアニメーション
                let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
                pulseAnimation.fromValue = 1.0
                pulseAnimation.toValue = 1.2
                pulseAnimation.duration = duration / 2
                pulseAnimation.autoreverses = true
                pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                slot.layer.add(pulseAnimation, forKey: "pulse")
                
                // グロー効果
                let glowAnimation = CABasicAnimation(keyPath: "shadowOpacity")
                glowAnimation.fromValue = 0
                glowAnimation.toValue = 1
                glowAnimation.duration = duration / 2
                glowAnimation.autoreverses = true
                slot.layer.shadowColor = UIColor.white.cgColor
                slot.layer.shadowRadius = 10
                slot.layer.add(glowAnimation, forKey: "glow")
            }
        }
        
        let totalDuration = duration * Double(gates.count) + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            completion()
        }
    }
}

// MARK: - UIDropInteractionDelegate

extension CircuitView: UIDropInteractionDelegate {
    
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: [UTType.plainText.identifier])
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        for item in session.items {
            if let gate = item.localObject as? QuantumGate {
                if gates.count < maxSlots {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    delegate?.circuitView(self, didReceiveGate: gate)
                }
            }
        }
    }
}
