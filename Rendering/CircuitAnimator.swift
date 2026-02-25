import UIKit

/// 正解・不正解時のパーティクルやシェイクなどのエフェクトを生成するユーティリティ
@MainActor
public final class CircuitAnimator {

    public static func showQuantumSuccessEffect(on view: UIView) {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = center
        emitter.emitterSize = CGSize(width: 10, height: 10)
        emitter.emitterShape = .circle
        emitter.renderMode = .additive

        let colors: [UIColor] = [.cyan, .purple, .white, .systemIndigo]
        var cells: [CAEmitterCell] = []

        for color in colors {
            let cell = CAEmitterCell()
            cell.contents = createQuantumParticleImage()?.cgImage
            cell.birthRate = 120
            cell.lifetime = 1.0
            cell.velocity = 200
            cell.velocityRange = 100
            cell.emissionRange = .pi * 2
            cell.scale = 0.08
            cell.scaleRange = 0.1
            cell.scaleSpeed = -0.08
            cell.alphaSpeed = -0.5
            cell.color = color.cgColor
            cell.spin = 2
            cell.spinRange = 4
            cells.append(cell)
        }

        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            emitter.removeFromSuperlayer()
        }
    }

    private static func createQuantumParticleImage() -> UIImage? {
        let size = CGSize(width: 32, height: 32)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

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

    public static func showFailureEffect(on view: UIView) {
        let shakeAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shakeAnimation.values = [0, -15, 15, -10, 10, -5, 5, 0]
        shakeAnimation.duration = 0.4
        shakeAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        view.layer.add(shakeAnimation, forKey: "shake")

        showPulseEffect(on: view, color: UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 0.3))
    }

}
