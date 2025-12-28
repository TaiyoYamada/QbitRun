// SPDX-License-Identifier: MIT
// Presentation/Game/DistanceGaugeView.swift
// 状態間の距離を表示するゲージ

import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// カスタムUIView描画
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// UIKitでカスタム描画するには：
// 1. draw(_ rect:) メソッドをオーバーライド
// 2. UIGraphicsGetCurrentContext() でグラフィックスコンテキストを取得
// 3. Core Graphics関数で描画
// 4. setNeedsDisplay() を呼ぶと再描画される
//
// SwiftUI               UIKit
// ─────────────────────────────────────────────────────────────────
// Path { }              CGContext.addPath()
// .fill(), .stroke()    context.fillPath(), strokePath()
// Color                 UIColor / CGColor
// Canvas { }            draw(_ rect:) + Core Graphics
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 現在の状態とターゲット状態の距離を表示するゲージ
/// 距離が近いほど緑、遠いほど赤で表示
@MainActor
public final class DistanceGaugeView: UIView {
    
    // MARK: - プロパティ
    
    /// 現在の距離（0〜2、ブロッホ球の直径）
    private var distance: Double = 2.0
    
    // MARK: - 初期化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 設定
    
    private func setupView() {
        backgroundColor = .clear
        isOpaque = false  // 透過描画を許可
    }
    
    // MARK: - 公開メソッド
    
    /// 距離を設定
    public func setDistance(_ distance: Double, animated: Bool = false) {
        let oldDistance = self.distance
        self.distance = max(0, min(2, distance))  // 0〜2にクランプ
        
        if animated {
            // アニメーション付きで更新
            animateDistance(from: oldDistance, to: self.distance)
        } else {
            // 即時更新
            setNeedsDisplay()  // 再描画を要求
        }
    }
    
    /// 距離をアニメーション付きで変更
    private func animateDistance(from: Double, to: Double) {
        // CADisplayLink を使ったアニメーション（Core Animationでは直接描画をアニメーションできないため）
        let duration: TimeInterval = 0.2
        let startTime = CACurrentMediaTime()
        
        // フレームごとに更新
        let displayLink = CADisplayLink { [weak self] link in
            guard let self = self else {
                link.invalidate()
                return
            }
            
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(elapsed / duration, 1.0)
            
            // 線形補間
            self.distance = from + (to - from) * progress
            self.setNeedsDisplay()
            
            if progress >= 1.0 {
                link.invalidate()
            }
        }
        displayLink.add(to: .main, forMode: .common)
    }
    
    // MARK: - 描画
    
    /// カスタム描画
    /// 親クラスのdraw()をオーバーライドして独自の描画を行う
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let padding: CGFloat = 4
        let barRect = CGRect(
            x: padding,
            y: padding,
            width: rect.width - padding * 2,
            height: rect.height - padding * 2
        )
        
        // 背景バー（グレー）
        context.setFillColor(UIColor.white.withAlphaComponent(0.1).cgColor)
        let backgroundPath = UIBezierPath(roundedRect: barRect, cornerRadius: barRect.height / 2)
        context.addPath(backgroundPath.cgPath)
        context.fillPath()
        
        // 進捗バー
        // 距離 0 = 100%（完全一致）、距離 2 = 0%（反対側）
        let progress = 1.0 - (distance / 2.0)
        let progressWidth = barRect.width * CGFloat(progress)
        
        if progressWidth > 0 {
            let progressRect = CGRect(
                x: barRect.origin.x,
                y: barRect.origin.y,
                width: progressWidth,
                height: barRect.height
            )
            
            // 色を距離に応じて変化させる
            let color = colorForDistance(distance)
            context.setFillColor(color.cgColor)
            
            let progressPath = UIBezierPath(roundedRect: progressRect, cornerRadius: barRect.height / 2)
            context.addPath(progressPath.cgPath)
            context.fillPath()
        }
        
        // ラベル
        let statusText = statusTextForDistance(distance)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let size = statusText.size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        statusText.draw(in: textRect, withAttributes: attributes)
    }
    
    /// 距離に応じた色を返す
    private func colorForDistance(_ distance: Double) -> UIColor {
        if distance < 0.2 {
            // 非常に近い = 緑
            return UIColor(red: 0.2, green: 0.9, blue: 0.4, alpha: 1)
        } else if distance < 0.5 {
            // 近い = 黄緑
            return UIColor(red: 0.6, green: 0.9, blue: 0.2, alpha: 1)
        } else if distance < 1.0 {
            // 中程度 = 黄色
            return UIColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1)
        } else if distance < 1.5 {
            // 遠い = オレンジ
            return UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1)
        } else {
            // 非常に遠い = 赤
            return UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
        }
    }
    
    /// 距離に応じたステータステキストを返す
    private func statusTextForDistance(_ distance: Double) -> String {
        if distance < 0.1 {
            return "Perfect!"
        } else if distance < 0.3 {
            return "Very Close"
        } else if distance < 0.7 {
            return "Close"
        } else if distance < 1.2 {
            return "Getting There"
        } else {
            return "Far"
        }
    }
}

// MARK: - CADisplayLink拡張
// ブロックベースのCADisplayLinkを作成するためのヘルパー

private extension CADisplayLink {
    private class Target {
        let block: (CADisplayLink) -> Void
        init(_ block: @escaping (CADisplayLink) -> Void) {
            self.block = block
        }
        @objc func tick(_ link: CADisplayLink) {
            block(link)
        }
    }
    
    convenience init(block: @escaping (CADisplayLink) -> Void) {
        let target = Target(block)
        self.init(target: target, selector: #selector(Target.tick))
        // targetを保持するためにassociated objectを使用
        objc_setAssociatedObject(self, "target", target, .OBJC_ASSOCIATION_RETAIN)
    }
}
