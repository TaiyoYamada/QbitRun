import UIKit

/// 回路アニメーションを管理
@MainActor
public final class CircuitAnimator {
    
    // MARK: - 成功アニメーション
    
    /// パーティクル爆発エフェクト
    public static func showSuccessEffect(on view: UIView) {
        // パーティクルエミッター
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        emitter.emitterSize = CGSize(width: 50, height: 50)
        emitter.emitterShape = .circle
        emitter.renderMode = .additive
        
        // パーティクルセル
        let colors: [UIColor] = [
            UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1),  // 緑
            UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1),  // 青
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1),  // 黄
            UIColor(red: 0.8, green: 0.4, blue: 1.0, alpha: 1)   // 紫
        ]
        
        var cells: [CAEmitterCell] = []
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 80
            cell.lifetime = 1.5
            cell.velocity = 200
            cell.velocityRange = 100
            cell.emissionRange = .pi * 2
            cell.scale = 0.15
            cell.scaleRange = 0.1
            cell.scaleSpeed = -0.1
            cell.alphaSpeed = -0.7
            cell.color = color.cgColor
            cell.contents = createParticleImage()?.cgImage
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        
        // 0.5秒後にパーティクル生成を停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            emitter.birthRate = 0
        }
        
        // 2秒後にレイヤー削除
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitter.removeFromSuperlayer()
        }
        
        // 画面パルスエフェクト
        showPulseEffect(on: view, color: UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 0.3))
    }
    
    /// パーティクル用の画像を生成
    private static func createParticleImage() -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // グラデーション円
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
        
        context.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: 10, y: 10),
            startRadius: 0,
            endCenter: CGPoint(x: 10, y: 10),
            endRadius: 10,
            options: []
        )
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    /// 画面パルスエフェクト
    private static func showPulseEffect(on view: UIView, color: UIColor) {
        let pulseView = UIView(frame: view.bounds)
        pulseView.backgroundColor = color
        pulseView.alpha = 0
        view.addSubview(pulseView)
        
        UIView.animate(withDuration: 0.15, animations: {
            pulseView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                pulseView.alpha = 0
            }) { _ in
                pulseView.removeFromSuperview()
            }
        }
    }
    
    // MARK: - 失敗アニメーション
    
    /// 画面シェイク + 赤フラッシュ
    public static func showFailureEffect(on view: UIView) {
        // シェイクアニメーション
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.values = [0, -15, 15, -10, 10, -5, 5, 0]
        shakeAnimation.duration = 0.4
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(shakeAnimation, forKey: "shake")
        
        // 赤フラッシュ
        showPulseEffect(on: view, color: UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.3))
    }
    
    // MARK: - スコア表示アニメーション
    
    /// スコアポップアップ
    public static func showScorePopup(on view: UIView, score: Int, at position: CGPoint) {
        let label = UILabel()
        label.text = "+\(score)"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1)
        label.sizeToFit()
        label.center = position
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        view.addSubview(label)
        
        // ポップアップアニメーション
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            label.alpha = 1
            label.transform = .identity
        }
        
        // 上に移動して消える
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn) {
            label.alpha = 0
            label.transform = CGAffineTransform(translationX: 0, y: -50)
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
    
    // MARK: - 星エフェクト
    
    /// 星が飛び散るエフェクト
    public static func showStarsEffect(on view: UIView) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        emitter.emitterSize = CGSize(width: 100, height: 100)
        emitter.emitterShape = .circle
        
        let cell = CAEmitterCell()
        cell.birthRate = 30
        cell.lifetime = 2.0
        cell.velocity = 150
        cell.velocityRange = 80
        cell.emissionRange = .pi * 2
        cell.scale = 0.08
        cell.scaleRange = 0.04
        cell.alphaSpeed = -0.5
        cell.spin = 2.0
        cell.spinRange = 3.0
        cell.contents = createStarImage()?.cgImage
        
        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            emitter.birthRate = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            emitter.removeFromSuperlayer()
        }
    }
    
    /// 星形画像を生成
    private static func createStarImage() -> UIImage? {
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 星のパス
        let path = UIBezierPath()
        let center = CGPoint(x: 25, y: 25)
        let points = 5
        let outerRadius: CGFloat = 24
        let innerRadius: CGFloat = 10
        
        for i in 0..<points * 2 {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.close()
        
        context.setFillColor(UIColor.yellow.cgColor)
        context.addPath(path.cgPath)
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
