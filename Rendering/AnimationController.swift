import UIKit

@MainActor
public final class AnimationController {

    public static func createSuccessEffect(in layer: CALayer, at position: CGPoint) {
        let emitterLayer = CAEmitterLayer()
        emitterLayer.emitterPosition = position
        emitterLayer.emitterShape = .point
        emitterLayer.emitterSize = CGSize(width: 1, height: 1)

        let cell = CAEmitterCell()
        cell.birthRate = 50
        cell.lifetime = 0.8
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionRange = .pi * 2
        cell.scale = 0.1
        cell.scaleSpeed = -0.1
        cell.alphaSpeed = -1.5

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitterLayer.birthRate = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            emitterLayer.removeFromSuperlayer()
        }
    }

    public static func pulse(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.15, 1.0]
        animation.keyTimes = [0, 0.5, 1]
        animation.duration = 0.3
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        view.layer.add(animation, forKey: "pulse")
    }

    public static func shake(_ view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [0, -10, 10, -10, 10, -5, 5, 0]
        animation.duration = 0.4
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        view.layer.add(animation, forKey: "shake")
    }

    public static func slideOutRight(_ view: UIView, completion: @escaping () -> Void) {
        let slideAnimation = CABasicAnimation(keyPath: "position.x")
        slideAnimation.fromValue = view.layer.position.x
        slideAnimation.toValue = view.layer.position.x + 100

        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 1.0
        fadeAnimation.toValue = 0.0

        let group = CAAnimationGroup()
        group.animations = [slideAnimation, fadeAnimation]
        group.duration = 0.3
        group.timingFunction = CAMediaTimingFunction(name: .easeIn)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        view.layer.add(group, forKey: "slideOut")
        CATransaction.commit()
    }

    public static func addGlowPulse(to layer: CALayer, color: UIColor = .cyan) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = 10
        layer.shadowOpacity = 0
        layer.shadowOffset = .zero

        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0
        animation.toValue = 0.8
        animation.duration = 0.3
        animation.autoreverses = true
        animation.repeatCount = 2

        layer.add(animation, forKey: "glowPulse")
    }

    public static func pulseTimerWarning(_ label: UILabel) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.5
        animation.duration = 0.3
        animation.autoreverses = true
        animation.repeatCount = .infinity

        label.layer.add(animation, forKey: "timerPulse")
    }

    public static func stopTimerWarning(_ label: UILabel) {
        label.layer.removeAnimation(forKey: "timerPulse")
        label.layer.opacity = 1.0
    }
}
