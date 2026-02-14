import SwiftUI

// MARK: - アプリフォント定義

/// アプリ全体で使用するフォントスタイルを集約したデザインシステム
extension Font {
    // MARK: - フォント名
    
    private static let fontName = "Optima-Bold"
    private static let fontNameRegular = "Optima-Regular"
    
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
    
    /// 極小テキスト
    static let appCaptionSmall = Font.custom(fontNameRegular, size: 12)
    
    // MARK: - ボタン系
    
    /// ボタン（大）
    static let appButtonLarge = Font.custom(fontName, size: 24)
    
    /// ボタン（通常）
    static let appButton = Font.custom(fontName, size: 20)
    
    /// ボタン（小）
    static let appButtonSmall = Font.custom(fontName, size: 16)
    
    // MARK: - ゲーム用
    
    /// タイマー表示
    static let appTimer = Font.custom(fontName, size: 56)
    
    /// スコア表示（大）
    static let appScoreLarge = Font.custom(fontName, size: 32)
    
    /// スコア表示（中）
    static let appScore = Font.custom(fontName, size: 28)
    
    /// スコア表示（小）
    static let appScoreSmall = Font.custom(fontName, size: 24)
    
    /// ゲートシンボル
    static let appGateSymbol = Font.custom(fontName, size: 24)
    
    // MARK: - リザルト用
    
    /// リザルトスコア（カウントアップ）
    static let appResultScore = Font.custom(fontName, size: 72)
    
    /// リザルトランク
    static let appResultRank = Font.custom(fontName, size: 48)
}
