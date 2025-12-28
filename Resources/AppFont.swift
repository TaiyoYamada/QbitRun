// SPDX-License-Identifier: MIT
// Resources/AppFont.swift
// アプリ全体のフォント定義

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// アプリフォント
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// フォント名: Optima-Bold
//
// 使用例:
//   Text("Hello").font(.appTitle)
//   Text("World").font(.appBody)
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

extension Font {
    // MARK: - フォント名
    
    private static let fontName = "Optima-Bold"
    
    // MARK: - タイトル系
    
    /// 大タイトル（メイン画面など）
    static let appLargeTitle = Font.custom(fontName, size: 60)
    
    /// タイトル
    static let appTitle = Font.custom(fontName, size: 32)
    
    /// サブタイトル
    static let appSubtitle = Font.custom(fontName, size: 20)
    
    // MARK: - 本文系
    
    /// 本文
    static let appBody = Font.custom(fontName, size: 17)
    
    /// 小さい本文
    static let appCaption = Font.custom(fontName, size: 14)
    
    // MARK: - ボタン系
    
    /// ボタン（大）
    static let appButtonLarge = Font.custom(fontName, size: 24)
    
    /// ボタン（通常）
    static let appButton = Font.custom(fontName, size: 20)
    
    /// ボタン（小）
    static let appButtonSmall = Font.custom(fontName, size: 16)
    
    // MARK: - ゲーム用
    
    /// スコア表示
    static let appScore = Font.custom(fontName, size: 32)
    
    /// タイマー表示
    static let appTimer = Font.custom(fontName, size: 60)
    
    /// ゲートシンボル
    static let appGateSymbol = Font.custom(fontName, size: 24)
}
