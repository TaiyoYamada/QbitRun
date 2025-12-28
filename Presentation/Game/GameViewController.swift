// SPDX-License-Identifier: MIT
// Presentation/Game/GameViewController.swift
// メインゲーム画面

import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UIKitのUI構築パターン
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// SwiftUIでは body に宣言的にViewを書くが、
// UIKitでは以下の手順でUIを構築する：
//
// 1. lazy var で各UIコンポーネントを定義
// 2. viewDidLoad() で view.addSubview() して追加
// 3. NSLayoutConstraint.activate() で位置・サイズを設定
// 4. プロパティ変更時は手動でlabel.text = "..." などで更新
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// メインゲーム画面
/// ブロッホ球、回路、ゲートパレット、タイマー、スコアを表示
@MainActor
public final class GameViewController: UIViewController {
    
    // MARK: - プロパティ
    
    /// Coordinatorへの弱参照
    private weak var coordinator: AppCoordinator?
    
    /// ゲームロジックを管理するエンジン
    private let gameEngine: GameEngine
    
    // MARK: - UIコンポーネント
    
    /// 背景グラデーション
    private lazy var backgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
            UIColor(red: 0.08, green: 0.05, blue: 0.18, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1).cgColor
        ]
        layer.locations = [0, 0.5, 1]
        return layer
    }()
    
    /// タイマー表示ラベル
    /// monospacedDigitSystemFont: 数字の幅が固定されるフォント（時計向け）
    private lazy var timerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// スコア表示ラベル
    private lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        label.textColor = UIColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 解いた問題数ラベル
    private lazy var problemCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// ブロッホ球を囲むコンテナ
    private lazy var spheresContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 現在の状態を表すブロッホ球
    private lazy var currentSphereView: BlochSphereView = {
        let view = BlochSphereView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// ターゲット状態を表すブロッホ球
    private lazy var targetSphereView: BlochSphereView = {
        let view = BlochSphereView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 「Current」ラベル
    private lazy var currentLabel: UILabel = {
        let label = UILabel()
        label.text = "Current"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 「Target」ラベル
    private lazy var targetLabel: UILabel = {
        let label = UILabel()
        label.text = "Target"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 矢印ラベル
    private lazy var arrowLabel: UILabel = {
        let label = UILabel()
        label.text = "→"
        label.font = UIFont.systemFont(ofSize: 32, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 距離ゲージ（現在とターゲットの近さを表示）
    private lazy var distanceGauge: DistanceGaugeView = {
        let view = DistanceGaugeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// 回路ビュー（ゲートをドロップする場所）
    private lazy var circuitView: CircuitView = {
        let view = CircuitView()
        view.delegate = self  // デリゲートパターン：イベントを受け取る
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// ゲートパレット（ドラッグ元）
    private lazy var gatePaletteView: GatePaletteView = {
        let view = GatePaletteView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// クリアボタン
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - 初期化
    
    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.gameEngine = GameEngine()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ライフサイクル
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGameEngine()
    }
    
    /// 画面が表示された後に呼ばれる
    /// ゲームを開始するタイミング
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameEngine.start()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    // MARK: - UI構築
    
    private func setupUI() {
        view.layer.addSublayer(backgroundGradient)
        
        // 戻るボタンを非表示
        navigationItem.hidesBackButton = true
        
        // Viewを追加
        view.addSubview(timerLabel)
        view.addSubview(scoreLabel)
        view.addSubview(problemCountLabel)
        view.addSubview(spheresContainer)
        view.addSubview(distanceGauge)
        view.addSubview(circuitView)
        view.addSubview(gatePaletteView)
        view.addSubview(clearButton)
        
        spheresContainer.addSubview(currentSphereView)
        spheresContainer.addSubview(targetSphereView)
        spheresContainer.addSubview(currentLabel)
        spheresContainer.addSubview(targetLabel)
        spheresContainer.addSubview(arrowLabel)
        
        let sphereSize: CGFloat = 150
        
        // Auto Layout 制約
        NSLayoutConstraint.activate([
            // タイマー
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            
            // スコア
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 4),
            
            // 問題数
            problemCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            problemCountLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 4),
            
            // ブロッホ球コンテナ
            spheresContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spheresContainer.topAnchor.constraint(equalTo: problemCountLabel.bottomAnchor, constant: 24),
            spheresContainer.heightAnchor.constraint(equalToConstant: sphereSize + 30),
            
            // 現在のブロッホ球（左）
            currentSphereView.leadingAnchor.constraint(equalTo: spheresContainer.leadingAnchor),
            currentSphereView.topAnchor.constraint(equalTo: spheresContainer.topAnchor),
            currentSphereView.widthAnchor.constraint(equalToConstant: sphereSize),
            currentSphereView.heightAnchor.constraint(equalToConstant: sphereSize),
            
            currentLabel.centerXAnchor.constraint(equalTo: currentSphereView.centerXAnchor),
            currentLabel.topAnchor.constraint(equalTo: currentSphereView.bottomAnchor, constant: 4),
            
            // 矢印
            arrowLabel.centerYAnchor.constraint(equalTo: currentSphereView.centerYAnchor),
            arrowLabel.leadingAnchor.constraint(equalTo: currentSphereView.trailingAnchor, constant: 16),
            
            // ターゲットのブロッホ球（右）
            targetSphereView.leadingAnchor.constraint(equalTo: arrowLabel.trailingAnchor, constant: 16),
            targetSphereView.trailingAnchor.constraint(equalTo: spheresContainer.trailingAnchor),
            targetSphereView.topAnchor.constraint(equalTo: spheresContainer.topAnchor),
            targetSphereView.widthAnchor.constraint(equalToConstant: sphereSize),
            targetSphereView.heightAnchor.constraint(equalToConstant: sphereSize),
            
            targetLabel.centerXAnchor.constraint(equalTo: targetSphereView.centerXAnchor),
            targetLabel.topAnchor.constraint(equalTo: targetSphereView.bottomAnchor, constant: 4),
            
            // 距離ゲージ
            distanceGauge.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            distanceGauge.topAnchor.constraint(equalTo: spheresContainer.bottomAnchor, constant: 16),
            distanceGauge.widthAnchor.constraint(equalToConstant: 200),
            distanceGauge.heightAnchor.constraint(equalToConstant: 24),
            
            // 回路ビュー
            circuitView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            circuitView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            circuitView.topAnchor.constraint(equalTo: distanceGauge.bottomAnchor, constant: 24),
            circuitView.heightAnchor.constraint(equalToConstant: 70),
            
            // クリアボタン
            clearButton.trailingAnchor.constraint(equalTo: circuitView.trailingAnchor),
            clearButton.topAnchor.constraint(equalTo: circuitView.bottomAnchor, constant: 8),
            clearButton.widthAnchor.constraint(equalToConstant: 60),
            clearButton.heightAnchor.constraint(equalToConstant: 32),
            
            // ゲートパレット
            gatePaletteView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            gatePaletteView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            gatePaletteView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            gatePaletteView.heightAnchor.constraint(equalToConstant: 76)
        ])
        
        // 初期値を設定
        updateTimerDisplay(60)
        updateScoreDisplay(0, solved: 0)
    }
    
    /// ゲームエンジンの設定
    private func setupGameEngine() {
        // デリゲートパターン：ゲームエンジンからのイベントを受け取る
        gameEngine.delegate = self
    }
    
    // MARK: - UI更新メソッド
    
    /// タイマー表示を更新
    private func updateTimerDisplay(_ time: TimeInterval) {
        let seconds = Int(max(0, time))
        timerLabel.text = String(format: "%02d", seconds)
        
        // 残り時間で色を変える
        if time <= 10 {
            timerLabel.textColor = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1)
        } else if time <= 20 {
            timerLabel.textColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1)
        } else {
            timerLabel.textColor = .white
        }
    }
    
    /// スコア表示を更新
    private func updateScoreDisplay(_ score: Int, solved: Int) {
        scoreLabel.text = "\(score) pts"
        problemCountLabel.text = "Solved: \(solved)"
    }
    
    // MARK: - アクション
    
    /// クリアボタンタップ時
    @objc private func clearTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        gameEngine.clearCircuit()
        circuitView.updateCircuit([])
    }
}

// MARK: - GameEngineDelegate
// デリゲートパターン：ゲームエンジンからのイベントを処理

extension GameViewController: GameEngineDelegate {
    
    /// ゲーム開始時
    public func gameDidStart() {
        currentSphereView.setVector(.zero)
        distanceGauge.setDistance(2.0)
    }
    
    /// タイマー更新時（毎秒呼ばれる）
    public func gameDidUpdateTime(remaining: TimeInterval) {
        updateTimerDisplay(remaining)
    }
    
    /// 問題を正解した時
    public func gameDidSolveProblem(score: Int, bonus: Int) {
        updateScoreDisplay(score, solved: gameEngine.problemsSolved)
        
        // 成功ハプティクス
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // パーティクルエフェクト
        AnimationController.createSuccessEffect(in: view.layer, at: currentSphereView.center)
        AnimationController.addGlowPulse(to: currentSphereView.layer, color: .cyan)
        
        // ゲートをスライドアウト
        circuitView.animateGatesOut { [weak self] in
            self?.currentSphereView.setVector(.zero)
        }
        
        // スコアラベルをパルス
        AnimationController.pulse(scoreLabel)
        
        // 画面フラッシュ
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.cyan.withAlphaComponent(0.1)
        view.insertSubview(flashView, at: 1)
        
        UIView.animate(withDuration: 0.3, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
        }
    }
    
    /// 新しい問題が生成された時
    public func gameDidGenerateNewProblem(_ problem: Problem) {
        targetSphereView.setVector(problem.targetBlochVector, animated: true)
        let distance = BlochVector.zero.distance(to: problem.targetBlochVector)
        distanceGauge.setDistance(distance)
    }
    
    /// 回路の状態が変わった時
    public func gameDidUpdateCurrentState(_ state: QuantumState, blochVector: BlochVector) {
        currentSphereView.setVector(blochVector, animated: false)
        
        if let problem = gameEngine.currentProblem {
            let distance = blochVector.distance(to: problem.targetBlochVector)
            distanceGauge.setDistance(distance, animated: true)
        }
        
        circuitView.updateCircuit(gameEngine.currentCircuit.gates)
    }
    
    /// ゲーム終了時
    public func gameDidFinish(finalScore: ScoreEntry) {
        coordinator?.showResult(score: finalScore)
    }
}

// MARK: - CircuitViewDelegate
// 回路ビューからのイベントを処理

extension GameViewController: CircuitViewDelegate {
    
    /// ゲートがドロップされた時
    public func circuitView(_ view: CircuitView, didReceiveGate gate: QuantumGate) {
        gameEngine.addGate(gate)
    }
    
    /// ゲートが削除された時
    public func circuitView(_ view: CircuitView, didRemoveGateAt index: Int) {
        gameEngine.removeGate(at: index)
    }
}

// MARK: - GatePaletteViewDelegate
// ゲートパレットからのイベントを処理

extension GameViewController: GatePaletteViewDelegate {
    
    /// ゲートがタップで選択された時
    public func gatePalette(_ palette: GatePaletteView, didSelectGate gate: QuantumGate) {
        gameEngine.addGate(gate)
    }
}
