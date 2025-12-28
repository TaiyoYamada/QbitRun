// SPDX-License-Identifier: MIT
// Presentation/Game/CircuitView.swift
// 量子回路ビュー（ゲートをドロップする場所）

import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UIDropInteraction とは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// iOS 11以降のドラッグ＆ドロップAPI：
//
// ドラッグ側: UIDragInteraction + UIDragInteractionDelegate
// ドロップ側: UIDropInteraction + UIDropInteractionDelegate
//
// 処理の流れ：
// 1. ユーザーがGatePaletteViewからドラッグ開始
// 2. CircuitView上にドラッグしてくると canHandle が呼ばれる
// 3. ドロップすると performDrop が呼ばれる
// 4. デリゲートでGameViewControllerに通知
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 回路ビューのイベントを通知するデリゲート
@MainActor
public protocol CircuitViewDelegate: AnyObject {
    /// ゲートがドロップされた時
    func circuitView(_ view: CircuitView, didReceiveGate gate: QuantumGate)
    /// ゲートが削除された時
    func circuitView(_ view: CircuitView, didRemoveGateAt index: Int)
}

/// 量子回路ビュー
/// ゲートをドロップして回路を構築する
@MainActor
public final class CircuitView: UIView {
    
    // MARK: - 定数
    
    /// 最大ゲート数
    private let maxSlots = 6
    
    // MARK: - プロパティ
    
    public weak var delegate: CircuitViewDelegate?
    
    /// 現在配置されているゲート
    private var gates: [QuantumGate] = []
    
    /// 各スロットのビュー
    private var slotViews: [UIView] = []
    
    /// ゲートスロットを横に並べるスタック
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
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
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        
        addSubview(stackView)
        
        // 空のスロットを作成
        for _ in 0..<maxSlots {
            let slot = createEmptySlot()
            slotViews.append(slot)
            stackView.addArrangedSubview(slot)
        }
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        // ドロップ機能を追加
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
    }
    
    /// 空のスロットを作成
    private func createEmptySlot() -> UIView {
        let slot = UIView()
        slot.backgroundColor = UIColor.white.withAlphaComponent(0.03)
        slot.layer.cornerRadius = 8
        slot.layer.borderWidth = 1
        slot.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        return slot
    }
    
    // MARK: - 公開メソッド
    
    /// 回路を更新（配置されたゲートを再描画）
    public func updateCircuit(_ gates: [QuantumGate]) {
        self.gates = gates
        
        // 全スロットを更新
        for (index, slot) in slotViews.enumerated() {
            // 既存のサブビューを削除
            slot.subviews.forEach { $0.removeFromSuperview() }
            
            if index < gates.count {
                // ゲートを表示
                let gate = gates[index]
                let label = UILabel()
                label.text = gate.symbol
                label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
                label.textColor = .white
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                
                slot.addSubview(label)
                slot.backgroundColor = gate.color.withAlphaComponent(0.8)
                
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: slot.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: slot.centerYAnchor)
                ])
                
                // タップで削除できるようにする
                setupTapToRemove(for: slot, at: index)
            } else {
                // 空のスロット
                slot.backgroundColor = UIColor.white.withAlphaComponent(0.03)
            }
        }
    }
    
    /// タップで削除する機能を追加
    private func setupTapToRemove(for slot: UIView, at index: Int) {
        // 既存のジェスチャーを削除
        slot.gestureRecognizers?.forEach { slot.removeGestureRecognizer($0) }
        
        // タップジェスチャーを追加
        let tap = UITapGestureRecognizer(target: self, action: #selector(slotTapped(_:)))
        slot.addGestureRecognizer(tap)
        slot.tag = index
        slot.isUserInteractionEnabled = true
    }
    
    @objc private func slotTapped(_ gesture: UITapGestureRecognizer) {
        guard let slot = gesture.view else { return }
        let index = slot.tag
        
        // 触覚フィードバック
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // デリゲートに通知
        delegate?.circuitView(self, didRemoveGateAt: index)
    }
    
    /// ゲートをスライドアウトするアニメーション
    public func animateGatesOut(completion: @escaping () -> Void) {
        // 各ゲートを順番にスライドアウト
        let animationDuration = 0.15
        
        for (index, slot) in slotViews.enumerated() {
            guard index < gates.count else { continue }
            
            // 遅延付きでアニメーション
            UIView.animate(
                withDuration: animationDuration,
                delay: Double(index) * 0.05,
                options: .curveEaseIn,
                animations: {
                    slot.transform = CGAffineTransform(translationX: 50, y: 0)
                    slot.alpha = 0
                }
            ) { _ in
                slot.transform = .identity
                slot.alpha = 1
            }
        }
        
        // 全アニメーション完了後にコールバック
        let totalDuration = animationDuration + Double(gates.count) * 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            completion()
        }
    }
}

// MARK: - UIDropInteractionDelegate
// ドロップ操作のデリゲート

extension CircuitView: UIDropInteractionDelegate {
    
    /// このViewがドロップを受け付けるか判定
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        canHandle session: UIDropSession
    ) -> Bool {
        // NSStringを含むアイテムを受け付ける
        return session.hasItemsConforming(toTypeIdentifiers: [UTType.plainText.identifier])
    }
    
    /// ドロップ時の提案を返す
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        sessionDidUpdate session: UIDropSession
    ) -> UIDropProposal {
        // .copy: コピー操作として扱う
        return UIDropProposal(operation: .copy)
    }
    
    /// 実際にドロップされた時の処理
    public func dropInteraction(
        _ interaction: UIDropInteraction,
        performDrop session: UIDropSession
    ) {
        // ドラッグアイテムからゲートを取得
        for item in session.items {
            if let gate = item.localObject as? QuantumGate {
                // 最大数チェック
                if gates.count < maxSlots {
                    // 触覚フィードバック
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // デリゲートに通知
                    delegate?.circuitView(self, didReceiveGate: gate)
                }
            }
        }
    }
}

// UTType を使うために必要
import UniformTypeIdentifiers
