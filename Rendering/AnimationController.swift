import UIKit

/// ゲームのフィードバック（成功エフェクト等）で使用
@MainActor
public final class AnimationController {
    
    public static func createSuccessEffect(in layer: CALayer, at position: CGPoint) {
        // CAEmitterLayer: パーティクルを発生させるレイヤー
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = position
        emitterLayer.emitterShape = .point  // 1点から発生
        emitterLayer.emitterSize = CGSize(width: 1, height: 1)
        
        // CAEmitterCell: 1種類のパーティクルの設定
        let cell = CAEmitterCell()
        cell.birthRate = 50         // 1秒あたりの発生数
        cell.lifetime = 0.8         // パーティクルの寿命（秒）
        cell.velocity = 150         // 初速
        cell.velocityRange = 50     // 速度のばらつき
        cell.emissionRange = .pi * 2  // 360度全方向に発射
        cell.scale = 0.1            // 初期サイズ
        cell.scaleSpeed = -0.1      // サイズの変化速度（縮小）
        cell.alphaSpeed = -1.5      // 透明度の変化速度（フェードアウト）
        
        // パーティクル画像を作成（円形）
        let size: CGFloat = 20
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0)
        UIColor.cyan.setFill()
        UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        cell.contents = image?.cgImage
        cell.color = UIColor.white.cgColor
        
        emitterLayer.emitterCells = [cell]
        layer.addSublayer(emitterLayer)
        
        // 短時間だけ発生させて停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitterLayer.birthRate = 0
        }
        
        // パーティクルが消えたらレイヤーを削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitterLayer.removeFromSuperlayer()
        }
    }
    
    // MARK: - ビューアニメーション
    
    /// パルスエフェクト（拡大→縮小）
    /// スコアラベルの強調などに使用
    public static func pulse(_ view: UIView) {
        // CAKeyframeAnimation: 複数のキーフレームを指定するアニメーション
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.15, 1.0]     // 開始 → 拡大 → 終了
        animation.keyTimes = [0, 0.5, 1]         // タイミング（0〜1）
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(animation, forKey: "pulse")
    }
    
    /// シェイクエフェクト（左右に揺れる）
    /// エラー時のフィードバックに使用
    public static func shake(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -10, 10, -10, 10, -5, 5, 0]
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        view.layer.add(animation, forKey: "shake")
    }
    
    // MARK: - ゲートアニメーション
    
    /// スライドアウト＋フェード
    /// 正解時にゲートが画面外へ消えていくアニメーション
    public static func slideOutRight(_ view: UIView, completion: @escaping () -> Void) {
        // 位置のアニメーション
        let slideAnimation = CABasicAnimation(keyPath: "position.x")
        slideAnimation.fromValue = view.layer.position.x
        slideAnimation.toValue = view.layer.position.x + 100
        
        // 透明度のアニメーション
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 1.0
        fadeAnimation.toValue = 0.0
        
        // グループ化
        let group = CAAnimationGroup()
        group.animations = [slideAnimation, fadeAnimation]
        group.duration = 0.3
        group.timingFunction = CAMediaTimingFunction(name: .easeIn)
        group.fillMode = .forwards          // アニメーション後の状態を維持
        group.isRemovedOnCompletion = false // 自動削除しない
        
        // 完了コールバック
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        view.layer.add(group, forKey: "slideOut")
        CATransaction.commit()
    }
    
    // MARK: - グローエフェクト
    
    /// グロー（発光）パルス
    /// ブロッホ球が正解状態に近づいた時の強調
    public static func addGlowPulse(to layer: CALayer, color: UIColor = .cyan) {
        // シャドウをグローとして使用
        layer.shadowColor = color.cgColor
        layer.shadowRadius = 10
        layer.shadowOpacity = 0
        layer.shadowOffset = .zero
        
        // 透明度をアニメーション
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0
        animation.toValue = 0.8
        animation.duration = 0.3
        animation.autoreverses = true  // 戻りアニメーションも実行
        animation.repeatCount = 2
        
        layer.add(animation, forKey: "glowPulse")
    }
    
    // MARK: - タイマー警告
    
    /// タイマー警告アニメーション（点滅）
    public static func pulseTimerWarning(_ label: UILabel) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.5
        animation.duration = 0.3
        animation.autoreverses = true
        animation.repeatCount = .infinity  // 無限ループ
        
        label.layer.add(animation, forKey: "timerPulse")
    }
    
    /// タイマー警告アニメーションを停止
    public static func stopTimerWarning(_ label: UILabel) {
        label.layer.removeAnimation(forKey: "timerPulse")
        label.layer.opacity = 1.0
    }
}
