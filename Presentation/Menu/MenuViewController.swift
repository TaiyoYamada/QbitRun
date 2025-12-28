// SPDX-License-Identifier: MIT
// Presentation/Menu/MenuViewController.swift
// メニュー画面（スタート画面）

import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UIViewController とは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// SwiftUIでは View struct が画面を表すが、
// UIKitでは UIViewController class が「1画面」を管理する。
//
// SwiftUI                    UIKit
// ─────────────────────────────────────────────────────────────────
// struct ContentView: View   class MenuViewController: UIViewController
// var body: some View        func viewDidLoad() + UI構築コード
// @State var                 var + 手動で更新
// .onAppear { }              func viewDidAppear(_ animated:)
// .onDisappear { }           func viewDidDisappear(_ animated:)
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// メニュー画面
/// スタートボタンとハイスコアを表示する
@MainActor
public final class MenuViewController: UIViewController {
    
    // MARK: - プロパティ
    
    /// 画面遷移を依頼するためのCoordinatorへの参照
    /// weak: 循環参照を防ぐため弱参照にする
    private weak var coordinator: AppCoordinator?
    
    /// スコア保存・読み込み用のリポジトリ
    private let scoreRepository = ScoreRepository()
    
    // MARK: - UIコンポーネント
    // UIKitでは、SwiftUIと違って各UIパーツを手動で作成・配置する
    
    /// 背景のグラデーション
    /// CAGradientLayer: Core Animationのレイヤー、UIViewの下に敷く
    private lazy var backgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
            UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.1, blue: 0.2, alpha: 1).cgColor
        ]
        layer.locations = [0, 0.5, 1]  // グラデーションの位置
        return layer
    }()
    
    /// タイトルラベル
    /// UILabel: SwiftUIの Text に相当
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Quantum Gate"
        label.font = UIFont.systemFont(ofSize: 42, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        
        // Auto Layout を使うために必須の設定
        // false にしないと手動で設定した制約が効かない
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// サブタイトルラベル
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Master the Bloch Sphere"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// スタートボタン
    /// UIButton: SwiftUIの Button に相当
    private lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Game", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // タップ時のアクションを設定
        // SwiftUIの Button { action } に相当
        button.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        return button
    }()
    
    /// ハイスコア表示ラベル
    private lazy var highScoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 説明テキスト
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Drag quantum gates to transform |0⟩\ninto the target state within 60 seconds"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.numberOfLines = 0  // 複数行表示を許可
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - 初期化
    
    /// イニシャライザ
    /// SwiftUIでいう init() に相当
    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    /// Storyboardからの初期化（このアプリでは使わない）
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ライフサイクルメソッド
    // UIViewControllerは、画面表示の各段階で特定のメソッドが呼ばれる
    
    /// 画面のViewが読み込まれた時に呼ばれる（1回だけ）
    /// SwiftUIでいう body の最初の評価 + .onAppear の一部
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()        // UIを構築
        loadHighScore()  // ハイスコアを読み込み
    }
    
    /// 画面サイズが変わった時に呼ばれる
    /// グラデーションのサイズを画面に合わせる
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    /// 画面が表示される直前に呼ばれる（毎回）
    /// 他の画面から戻ってきた時にもう一度ハイスコアを更新
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadHighScore()
    }
    
    // MARK: - UI構築
    
    /// UIコンポーネントを配置する
    /// SwiftUIではbodyに書くが、UIKitでは手動で追加・制約を設定
    private func setupUI() {
        // 1. グラデーションをViewのレイヤーに追加
        view.layer.addSublayer(backgroundGradient)
        
        // 2. 各UIコンポーネントをViewに追加
        //    SwiftUIの VStack { Text(...); Button(...) } に相当
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(startButton)
        view.addSubview(highScoreLabel)
        view.addSubview(instructionLabel)
        
        // 3. Auto Layout制約を設定
        //    SwiftUIの .frame(), .padding() などに相当
        NSLayoutConstraint.activate([
            // タイトル：中央、やや上
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            
            // サブタイトル：タイトルの下
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            
            // スタートボタン：サブタイトルの下
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 56),
            
            // ハイスコア：ボタンの下
            highScoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            highScoreLabel.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 24),
            
            // 説明：画面下部
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    /// ハイスコアを非同期で読み込んで表示
    private func loadHighScore() {
        // Task: SwiftUIの .task { } に相当
        Task {
            let highScore = await scoreRepository.highScore()
            if highScore > 0 {
                highScoreLabel.text = "High Score: \(highScore)"
            } else {
                highScoreLabel.text = "No scores yet"
            }
        }
    }
    
    // MARK: - アクション
    
    /// スタートボタンがタップされた時に呼ばれる
    /// @objc: Objective-Cランタイムから呼び出し可能にするために必要
    @objc private func startTapped() {
        // ボタンのアニメーション効果
        UIView.animate(withDuration: 0.1, animations: {
            self.startButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.startButton.transform = .identity
            }
        }
        
        // 触覚フィードバック（iPhoneが振動）
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Coordinatorにゲーム画面への遷移を依頼
        coordinator?.showGame()
    }
}
