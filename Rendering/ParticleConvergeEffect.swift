import UIKit

@MainActor
public final class ParticleConvergeEffectView: UIView {

    private static let glowColor = UIColor(red: 0.3, green: 0.9, blue: 1.0, alpha: 1.0)

    private let particleCount: Int = 12

    private var particleLayers: [CALayer] = []

    private var convergeRingLayer: CAShapeLayer?

    public var onConvergeComplete: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未実装です")
    }

    public func startEffect(sourcePoints: [CGPoint], targetCenter: CGPoint) {
        cleanup()

        createConvergeRing(at: targetCenter)

        for (index, sourcePoint) in sourcePoints.enumerated() {
            let delay = Double(index) * 0.08

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.launchParticle(from: sourcePoint, to: targetCenter)
            }
        }

        let totalDuration = Double(sourcePoints.count) * 0.08 + 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) { [weak self] in
            self?.expandRingAndComplete(at: targetCenter)
        }
    }

    public func startEffectFromRightEdge(targetCenter: CGPoint) {
        let rightX = bounds.width - 20
        let spacing = bounds.height / 6

        var sourcePoints: [CGPoint] = []
        for i in 0..<5 {
            let y = spacing * CGFloat(i + 1)
            sourcePoints.append(CGPoint(x: rightX, y: y))
        }

        startEffect(sourcePoints: sourcePoints, targetCenter: targetCenter)
    }

    public func cleanup() {
        particleLayers.forEach { $0.removeFromSuperlayer() }
        particleLayers.removeAll()
        convergeRingLayer?.removeFromSuperlayer()
        convergeRingLayer = nil
    }

    private func createConvergeRing(at center: CGPoint) {
        let ring = CAShapeLayer()
        let initialRadius: CGFloat = 5

        ring.path = UIBezierPath(
            arcCenter: center,
            radius: initialRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath

        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = Self.glowColor.cgColor
        ring.lineWidth = 2
        ring.opacity = 0.8

        layer.addSublayer(ring)
        convergeRingLayer = ring

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.8
        pulse.toValue = 1.2
        pulse.duration = 0.4
        pulse.autoreverses = true
        pulse.repeatCount = .greatestFiniteMagnitude
        ring.add(pulse, forKey: "pulse")
    }

    private func launchParticle(from source: CGPoint, to target: CGPoint) {
        let particle = CALayer()
        let size: CGFloat = 8

        particle.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        particle.position = source
        particle.backgroundColor = Self.glowColor.cgColor
        particle.cornerRadius = size / 2

        particle.shadowColor = Self.glowColor.cgColor
        particle.shadowRadius = 4
        particle.shadowOpacity = 0.8
        particle.shadowOffset = .zero

        layer.addSublayer(particle)
        particleLayers.append(particle)

        let path = createCurvePath(from: source, to: target)

        let moveAnimation = CAKeyframeAnimation(keyPath: "position")
        moveAnimation.path = path.cgPath
        moveAnimation.duration = 0.6
        moveAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        moveAnimation.fillMode = .forwards
        moveAnimation.isRemovedOnCompletion = false

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 0.3
        scaleAnimation.duration = 0.6
        scaleAnimation.fillMode = .forwards
        scaleAnimation.isRemovedOnCompletion = false

        particle.add(moveAnimation, forKey: "move")
        particle.add(scaleAnimation, forKey: "scale")
    }

    private func createCurvePath(from source: CGPoint, to target: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: source)

        let controlY = min(source.y, target.y) - 80
        let controlX = (source.x + target.x) / 2

        path.addQuadCurve(to: target, controlPoint: CGPoint(x: controlX, y: controlY))

        return path
    }

    private func expandRingAndComplete(at center: CGPoint) {
        guard let ring = convergeRingLayer else {
            onConvergeComplete?()
            return
        }

        ring.removeAnimation(forKey: "pulse")

        let expandRadius: CGFloat = 150

        let expandPath = UIBezierPath(
            arcCenter: center,
            radius: expandRadius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath

        let pathAnimation = CABasicAnimation(keyPath: "path")
        pathAnimation.toValue = expandPath
        pathAnimation.duration = 0.4
        pathAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        pathAnimation.fillMode = .forwards
        pathAnimation.isRemovedOnCompletion = false

        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.toValue = 0
        fadeAnimation.duration = 0.4
        fadeAnimation.fillMode = .forwards
        fadeAnimation.isRemovedOnCompletion = false

        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.cleanup()
            self?.onConvergeComplete?()
        }
        ring.add(pathAnimation, forKey: "expand")
        ring.add(fadeAnimation, forKey: "fade")
        CATransaction.commit()
    }
}
