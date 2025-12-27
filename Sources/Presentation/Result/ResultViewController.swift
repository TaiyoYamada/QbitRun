// SPDX-License-Identifier: MIT
// Presentation/Result/ResultViewController.swift
// ゲーム終了画面（スコアとリーダーボード表示）

import UIKit

/// ゲーム終了後のリザルト画面
/// スコア、順位、Top5リーダーボード、再プレイボタンを表示
@MainActor
public final class ResultViewController: UIViewController {
    
    // MARK: - プロパティ
    
    private weak var coordinator: AppCoordinator?
    
    /// 今回のスコア情報
    private let score: ScoreEntry
    
    /// スコア保存用リポジトリ
    private let scoreRepository: ScoreRepository
    
    /// 今回のランキング順位
    private var rank: Int?
    
    // MARK: - UIコンポーネント
    
    private lazy var backgroundGradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1).cgColor,
            UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1).cgColor
        ]
        return layer
    }()
    
    /// 「Time's Up!」ラベル
    private lazy var gameOverLabel: UILabel = {
        let label = UILabel()
        label.text = "Time's Up!"
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// スコア表示（大きな数字）
    private lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 64, weight: .bold)
        label.textColor = UIColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 統計情報（解いた問題数、ボーナス）
    private lazy var statsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// ランキング順位表示
    private lazy var rankLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// 「Play Again」ボタン
    private lazy var playAgainButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play Again", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1)
        button.layer.cornerRadius = 14
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(playAgainTapped), for: .touchUpInside)
        return button
    }()
    
    /// 「Menu」ボタン
    private lazy var menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Menu", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .normal)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        return button
    }()
    
    /// リーダーボード用UIStackView
    /// SwiftUIの VStack に相当
    private lazy var leaderboardStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical  // 縦方向に積む
        stack.spacing = 8       // 要素間の間隔
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    /// リーダーボードタイトル
    private lazy var leaderboardTitle: UILabel = {
        let label = UILabel()
        label.text = "Top Scores"
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.8)
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - 初期化
    
    public init(coordinator: AppCoordinator, score: ScoreEntry, scoreRepository: ScoreRepository) {
        self.coordinator = coordinator
        self.score = score
        self.scoreRepository = scoreRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ライフサイクル
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        saveAndDisplayScore()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
    }
    
    // MARK: - UI構築
    
    private func setupUI() {
        view.layer.addSublayer(backgroundGradient)
        navigationItem.hidesBackButton = true
        
        view.addSubview(gameOverLabel)
        view.addSubview(scoreLabel)
        view.addSubview(statsLabel)
        view.addSubview(rankLabel)
        view.addSubview(playAgainButton)
        view.addSubview(menuButton)
        view.addSubview(leaderboardStack)
        
        // スコアと統計を表示
        scoreLabel.text = "\(score.score)"
        statsLabel.text = "Problems Solved: \(score.problemsSolved)\nBonus Points: \(score.bonusPoints)"
        
        NSLayoutConstraint.activate([
            gameOverLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gameOverLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            
            scoreLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scoreLabel.topAnchor.constraint(equalTo: gameOverLabel.bottomAnchor, constant: 16),
            
            statsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 12),
            
            rankLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rankLabel.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 16),
            
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.topAnchor.constraint(equalTo: rankLabel.bottomAnchor, constant: 32),
            playAgainButton.widthAnchor.constraint(equalToConstant: 180),
            playAgainButton.heightAnchor.constraint(equalToConstant: 50),
            
            menuButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            menuButton.topAnchor.constraint(equalTo: playAgainButton.bottomAnchor, constant: 12),
            menuButton.widthAnchor.constraint(equalToConstant: 180),
            menuButton.heightAnchor.constraint(equalToConstant: 50),
            
            leaderboardStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            leaderboardStack.topAnchor.constraint(equalTo: menuButton.bottomAnchor, constant: 40),
            leaderboardStack.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    /// スコアを保存してリーダーボードを表示
    private func saveAndDisplayScore() {
        Task {
            // スコアを保存して順位を取得
            rank = await scoreRepository.saveScore(score)
            
            if let rank = rank {
                rankLabel.text = "🏆 Rank #\(rank)"
            } else {
                rankLabel.text = ""
            }
            
            // Top5を取得して表示
            let topScores = await scoreRepository.fetchTopScores()
            displayLeaderboard(topScores)
        }
    }
    
    /// リーダーボードを表示
    private func displayLeaderboard(_ scores: [ScoreEntry]) {
        // 既存の要素をクリア
        leaderboardStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // タイトルを追加
        leaderboardStack.addArrangedSubview(leaderboardTitle)
        
        // Top5を追加
        for (index, entry) in scores.prefix(5).enumerated() {
            let label = UILabel()
            let isCurrentScore = entry.id == score.id
            label.text = "\(index + 1). \(entry.score) pts"
            label.font = UIFont.systemFont(ofSize: 14, weight: isCurrentScore ? .bold : .regular)
            label.textColor = isCurrentScore ?
                UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1) :
                UIColor.white.withAlphaComponent(0.6)
            label.textAlignment = .center
            leaderboardStack.addArrangedSubview(label)
        }
    }
    
    // MARK: - アクション
    
    @objc private func playAgainTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        coordinator?.playAgain()
    }
    
    @objc private func menuTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        coordinator?.returnToMenu()
    }
}
