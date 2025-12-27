// SPDX-License-Identifier: MIT
// Presentation/AppCoordinator.swift
// 画面遷移を一元管理するCoordinatorパターンの実装

import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Coordinatorパターンとは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// SwiftUIでは NavigationLink や NavigationPath で画面遷移を宣言的に書くが、
// UIKitでは「誰が次の画面を表示するか？」を明確に決める必要がある。
//
// Coordinatorパターンは画面遷移のロジックを一箇所に集約するパターン:
// - 各ViewControllerは「次の画面に行きたい」とCoordinatorに依頼するだけ
// - 実際のpush/popはCoordinatorが担当
// - ViewControllerは他のVCを知らなくてよい（疎結合）
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 画面遷移を管理するCoordinator
/// SwiftUIでいうと NavigationPath + @Environment(\.dismiss) を
/// まとめたような役割を持つ
@MainActor
public final class AppCoordinator {
    
    // MARK: - プロパティ
    
    /// UINavigationController: 画面のスタックを管理
    /// SwiftUIの NavigationStack に相当する
    /// push = 画面を上に積む、pop = 画面を戻る
    public let navigationController: UINavigationController
    
    /// スコア保存用のリポジトリ
    private let scoreRepository: ScoreRepository
    
    // MARK: - 初期化
    
    public init(
        navigationController: UINavigationController = UINavigationController(),
        scoreRepository: ScoreRepository = ScoreRepository()
    ) {
        self.navigationController = navigationController
        self.scoreRepository = scoreRepository
        
        // ナビゲーションバーの見た目を設定
        configureNavigationAppearance()
    }
    
    // MARK: - 画面遷移メソッド
    
    /// アプリ起動時に最初の画面を表示
    /// SwiftUIでいう NavigationStack の最初のViewを設定するイメージ
    public func start() {
        let menuVC = MenuViewController(coordinator: self)
        
        // setViewControllers: NavigationControllerの画面スタックを設定
        // [menuVC] = メニュー画面だけのスタック
        navigationController.setViewControllers([menuVC], animated: false)
    }
    
    /// ゲーム画面へ遷移
    /// SwiftUIでいう NavigationLink で次の画面に遷移するイメージ
    public func showGame() {
        let gameVC = GameViewController(coordinator: self)
        
        // pushViewController: 画面を「積む」
        // SwiftUIの path.append() に相当
        navigationController.pushViewController(gameVC, animated: true)
    }
    
    /// 結果画面へ遷移
    public func showResult(score: ScoreEntry) {
        let resultVC = ResultViewController(
            coordinator: self,
            score: score,
            scoreRepository: scoreRepository
        )
        navigationController.pushViewController(resultVC, animated: true)
    }
    
    /// メニュー画面へ戻る
    /// SwiftUIでいう dismiss() や path.removeLast() に相当
    public func returnToMenu() {
        // popToRootViewController: 最初の画面まで一気に戻る
        navigationController.popToRootViewController(animated: true)
    }
    
    /// もう一度プレイ（メニューに戻ってすぐゲーム開始）
    public func playAgain() {
        navigationController.popToRootViewController(animated: false)
        showGame()
    }
    
    // MARK: - 外観設定
    
    /// ナビゲーションバーの見た目をカスタマイズ
    private func configureNavigationAppearance() {
        // UINavigationBarAppearance: iOS 13以降の外観設定API
        let appearance = UINavigationBarAppearance()
        
        // 透明な背景にする
        appearance.configureWithTransparentBackground()
        
        // タイトルの文字色とフォント
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        // 設定を適用
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.tintColor = .white
        
        // ナビゲーションバーを非表示（このアプリでは使わない）
        navigationController.navigationBar.isHidden = true
    }
}
