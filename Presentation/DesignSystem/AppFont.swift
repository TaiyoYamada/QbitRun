import SwiftUI

// MARK: - アプリフォント定義

/// アプリ全体で使用するフォントスタイルを集約したデザインシステム
extension Font {
    // MARK: - タイトル系
    
    /// 大タイトル（メイン画面など）
    static let appLargeTitle = Font.system(size: 60, weight: .bold, design: .rounded)
    
    /// タイトル
    static let appTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    
    /// サブタイトル
    static let appSubtitle = Font.system(size: 20, weight: .medium, design: .rounded)
    
    // MARK: - 本文系
    
    /// 本文
    static let appBody = Font.system(size: 17, weight: .regular, design: .rounded)
    
    /// 小さい本文
    static let appCaption = Font.system(size: 14, weight: .regular, design: .rounded)
    
    /// 極小テキスト
    static let appCaptionSmall = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // MARK: - ボタン系
    
    /// ボタン（大）
    static let appButtonLarge = Font.system(size: 24, weight: .bold, design: .rounded)
    
    /// ボタン（通常）
    static let appButton = Font.system(size: 20, weight: .bold, design: .rounded)
    
    /// ボタン（小）
    static let appButtonSmall = Font.system(size: 16, weight: .bold, design: .rounded)
    
    // MARK: - ゲーム用
    
    /// タイマー表示
    static let appTimer = Font.system(size: 56, weight: .bold, design: .rounded).monospacedDigit()
    
    /// スコア表示（大）
    static let appScoreLarge = Font.system(size: 32, weight: .bold, design: .rounded).monospacedDigit()
    
    /// スコア表示（中）
    static let appScore = Font.system(size: 28, weight: .bold, design: .rounded).monospacedDigit()
    
    /// スコア表示（小）
    static let appScoreSmall = Font.system(size: 24, weight: .bold, design: .rounded).monospacedDigit()
    
    /// ゲートシンボル
    static let appGateSymbol = Font.system(size: 24, weight: .bold, design: .rounded)
    
    // MARK: - リザルト用
    
    /// リザルトスコア（カウントアップ）
    static let appResultScore = Font.system(size: 72, weight: .bold, design: .rounded).monospacedDigit()
    
    /// リザルトランク
    static let appResultRank = Font.system(size: 48, weight: .bold, design: .rounded)
}
