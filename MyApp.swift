// SPDX-License-Identifier: MIT
// MyApp.swift
// アプリのエントリーポイント（純粋UIKit版）

import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UIKit vs SwiftUI 基本概念の対応表:
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// SwiftUI                    UIKit
// ─────────────────────────────────────────────────────────────────
// @main struct App           @main class AppDelegate
// WindowGroup                UIWindow
// View                       UIView / UIViewController
// NavigationStack            UINavigationController
// @State / @Observable       プロパティ + didSet / delegate
// .onAppear                  viewDidAppear()
// body: some View            loadView() / viewDidLoad()
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// @main: SwiftUIの @main struct App と同じ役割
/// このクラスがアプリの起動ポイントになる
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - プロパティ
    
    /// UIWindow: アプリの「窓」
    /// SwiftUIのWindowGroupに相当する。全ての画面はこのwindow上に表示される
    var window: UIWindow?
    
    /// Coordinator: 画面遷移を管理するオブジェクト
    /// SwiftUIのNavigationPathに相当する役割
    private var coordinator: AppCoordinator?
    
    // MARK: - アプリ起動時に呼ばれるメソッド
    
    /// SwiftUIでいう App.init() + body が呼ばれるタイミングに相当
    /// アプリが起動したらこのメソッドが自動的に呼ばれる
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        // 1. UIWindowを作成（SwiftUIのWindowGroupに相当）
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        // 2. Coordinatorを作成して画面遷移の準備
        coordinator = AppCoordinator()
        coordinator?.start()  // 最初の画面（Menu）を表示
        
        // 3. NavigationControllerをwindowのrootに設定
        //    SwiftUIでいう NavigationStack { ... } の最初のViewを設定するイメージ
        window.rootViewController = coordinator?.navigationController
        
        // 4. 画面を表示
        window.makeKeyAndVisible()
        
        return true
    }
}
