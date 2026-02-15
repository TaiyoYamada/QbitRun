import UIKit

/// 回路アニメーションを管理
@MainActor
public final class CircuitAnimator {
    
    // MARK: - 成功アニメーション
    
    /// パーティクル爆発エフェクト
    public static func showQuantumSuccessEffect(on view: UIView) {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = center
        emitter.emitterSize = CGSize(width: 10, height: 10) // 発生源を小さく
        emitter.emitterShape = .circle
        emitter.renderMode = .additive
        
        let colors: [UIColor] = [.cyan, .purple, .white, .systemIndigo]
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.contents = createQuantumParticleImage()?.cgImage
            cell.birthRate = 120
            cell.lifetime = 1.0           // 少し長く残る
            cell.velocity = 200            // パッと散らばる
            cell.velocityRange = 100
            cell.emissionRange = .pi * 2
            cell.scale = 0.08             // 小さな粒子
            cell.scaleRange = 0.1
            cell.scaleSpeed = -0.08        // 徐々に小さくなる（完全に消えるように調整）
            cell.alphaSpeed = -0.5         // 徐々に消える
            cell.color = color.cgColor
            cell.spin = 2
            cell.spinRange = 4
            cells.append(cell)
        }
        
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        
        // エミッター停止（一瞬のバースト）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }
        
        // 掃除
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitter.removeFromSuperlayer()
        }
        
        // 4. 背景パルス -> 削除
    }
    
    /// 量子パーティクル画像（光る円）
    private static func createQuantumParticleImage() -> UIImage? {
        let size = CGSize(width: 32, height: 32)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 中心が白く、周りが透明になるグラデーション
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else { return nil }
        
        context.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: 16, y: 16),
            startRadius: 2,
            endCenter: CGPoint(x: 16, y: 16),
            endRadius: 16,
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
    

}
