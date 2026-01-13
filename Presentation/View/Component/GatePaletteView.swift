import UIKit

/// ゲート選択イベントを通知するデリゲート
@MainActor
public protocol GatePaletteViewDelegate: AnyObject {
    /// ゲートがタップで選択された時に呼ばれる
    func gatePalette(_ palette: GatePaletteView, didSelectGate gate: QuantumGate)
}

/// 量子ゲートのパレット
/// ユーザーがドラッグまたはタップしてゲートを選択する
@MainActor
public final class GatePaletteView: UIView {
    
    // MARK: - プロパティ
    
    /// デリゲート（イベント通知先）
    /// weak: 循環参照を防ぐため弱参照
    public weak var delegate: GatePaletteViewDelegate?
    
    /// 利用可能なゲートの一覧
    private let gates: [QuantumGate] = [.x, .y, .z, .h, .s, .t]
    
    /// 各ゲートに対応するボタン
    private var gateButtons: [UIButton] = []
    
    /// ボタンを横に並べるためのスタック
    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal       // 横方向に並べる
        stack.distribution = .equalSpacing  // 均等間隔
        stack.alignment = .center
        stack.spacing = 16             // ボタン間の隙間
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
        // 背景
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        layer.cornerRadius = 12
        
        addSubview(stackView)
        
        // 各ゲートのボタンを作成
        for gate in gates {
            let button = createGateButton(for: gate)
            gateButtons.append(button)
            stackView.addArrangedSubview(button)
            
            // ドラッグ機能を追加
            setupDragInteraction(for: button, gate: gate)
        }
        
        // スタックビューの制約
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    
    /// ゲートボタンを作成（円形）
    private func createGateButton(for gate: QuantumGate) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(gate.symbol, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = gate.color
        
        // 円形にするための設定
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 56).isActive = true
        button.heightAnchor.constraint(equalToConstant: 56).isActive = true
        button.layer.cornerRadius = 28  // 半径 = 幅/2 で正円
        button.clipsToBounds = true
        
        // ボタンにゲート情報を関連付け
        button.tag = gates.firstIndex(of: gate) ?? 0
        
        // タップイベント
        button.addTarget(self, action: #selector(gateButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    // MARK: - ドラッグ＆ドロップ
    
    /// ボタンにドラッグ機能を追加
    private func setupDragInteraction(for button: UIButton, gate: QuantumGate) {
        // UIDragInteraction: iOS 11以降のドラッグ機能
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.isEnabled = true
        button.addInteraction(dragInteraction)
    }
    
    // MARK: - アクション
    
    @objc private func gateButtonTapped(_ sender: UIButton) {
        let gate = gates[sender.tag]
        
        // ボタンのアニメーション
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        
        // 触覚フィードバック
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // デリゲートに通知
        delegate?.gatePalette(self, didSelectGate: gate)
    }
}

// MARK: - UIDragInteractionDelegate
// ドラッグ操作のデリゲート

extension GatePaletteView: UIDragInteractionDelegate {
    
    /// ドラッグが開始された時に呼ばれる
    /// 戻り値: ドラッグするアイテムの配列
    nonisolated public func dragInteraction(
        _ interaction: UIDragInteraction,
        itemsForBeginning session: UIDragSession
    ) -> [UIDragItem] {
        // MainActorに切り替えて処理
        return MainActor.assumeIsolated {
            guard let button = interaction.view as? UIButton else { return [] }
            
            let gate = gates[button.tag]
            
            // ドラッグするデータを作成
            // NSItemProvider: ドラッグ＆ドロップで渡すデータのコンテナ
            let provider = NSItemProvider(object: gate.symbol as NSString)
            let item = UIDragItem(itemProvider: provider)
            
            // ローカルオブジェクトとしてゲートを添付
            item.localObject = gate
            
            return [item]
        }
    }
    
    /// ドラッグ中のプレビュー表示をカスタマイズ
    nonisolated public func dragInteraction(
        _ interaction: UIDragInteraction,
        previewForLifting item: UIDragItem,
        session: UIDragSession
    ) -> UITargetedDragPreview? {
        return MainActor.assumeIsolated {
            guard let button = interaction.view as? UIButton else { return nil }
            
            // ドラッグ中に表示するプレビュー
            let parameters = UIDragPreviewParameters()
            parameters.backgroundColor = .clear
            
            return UITargetedDragPreview(view: button, parameters: parameters)
        }
    }
}

// MARK: - QuantumGate拡張（UIColor版）

extension QuantumGate {
    /// ゲートの色（UIKit用）
    var color: UIColor {
        switch self {
        case .x: return UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
        case .y: return UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1)
        case .z: return UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        case .h: return UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1)
        case .s: return UIColor(red: 0.7, green: 0.3, blue: 0.8, alpha: 1)
        case .t: return UIColor(red: 0.2, green: 0.7, blue: 0.7, alpha: 1)
        }
    }
}

