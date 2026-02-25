import UIKit

@MainActor
public final class QuantumCircuitAnimationView: UIView {

    private static let wireColor = UIColor(red: 0.0, green: 0.8, blue: 0.9, alpha: 1.0)

    private static let gateColor = UIColor.white

    private static let gateBackgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 0.9)

    private static let controlColor = UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)

    private let qubitCount = 5

    private var wireSpacing: CGFloat = 60

    private let gateSize: CGFloat = 48

    public var onAnimationComplete: (() -> Void)?

    public var onGatePassCenter: ((Int) -> Void)?

    private var wireLayers: [CAShapeLayer] = []

    private var gateLayers: [CALayer] = []

    private var containerLayer: CALayer?

    private struct GatePlacement {
        let type: GateType
        let qubit: Int
        let xPosition: CGFloat
    }

    private enum GateType {
        case h, x, y, z, s, t
        case cnotControl(target: Int)
        case cnotTarget

        var symbol: String {
            switch self {
            case .h: return "H"
            case .x: return "X"
            case .y: return "Y"
            case .z: return "Z"
            case .s: return "S"
            case .t: return "T"
            case .cnotControl: return "●"
            case .cnotTarget: return "⊕"
            }
        }
    }

    private let circuitLayout: [GatePlacement] = [
        GatePlacement(type: .h, qubit: 0, xPosition: 0.05),
        GatePlacement(type: .h, qubit: 2, xPosition: 0.05),
        GatePlacement(type: .h, qubit: 4, xPosition: 0.05),

        GatePlacement(type: .cnotControl(target: 1), qubit: 0, xPosition: 0.10),
        GatePlacement(type: .cnotTarget, qubit: 1, xPosition: 0.10),
        GatePlacement(type: .x, qubit: 3, xPosition: 0.10),

        GatePlacement(type: .t, qubit: 1, xPosition: 0.15),
        GatePlacement(type: .s, qubit: 4, xPosition: 0.15),
        GatePlacement(type: .z, qubit: 0, xPosition: 0.15),

        GatePlacement(type: .cnotControl(target: 2), qubit: 0, xPosition: 0.20),
        GatePlacement(type: .cnotTarget, qubit: 2, xPosition: 0.20),
        GatePlacement(type: .h, qubit: 3, xPosition: 0.20),

        GatePlacement(type: .t, qubit: 2, xPosition: 0.25),
        GatePlacement(type: .y, qubit: 1, xPosition: 0.25),
        GatePlacement(type: .s, qubit: 3, xPosition: 0.25),

        GatePlacement(type: .cnotControl(target: 3), qubit: 0, xPosition: 0.30),
        GatePlacement(type: .cnotTarget, qubit: 3, xPosition: 0.30),
        GatePlacement(type: .h, qubit: 4, xPosition: 0.30),

        GatePlacement(type: .s, qubit: 3, xPosition: 0.35),
        GatePlacement(type: .t, qubit: 1, xPosition: 0.35),
        GatePlacement(type: .z, qubit: 2, xPosition: 0.35),

        GatePlacement(type: .cnotControl(target: 4), qubit: 0, xPosition: 0.40),
        GatePlacement(type: .cnotTarget, qubit: 4, xPosition: 0.40),

        GatePlacement(type: .t, qubit: 4, xPosition: 0.45),
        GatePlacement(type: .h, qubit: 1, xPosition: 0.45),
        GatePlacement(type: .s, qubit: 0, xPosition: 0.45),
        GatePlacement(type: .x, qubit: 2, xPosition: 0.45),

        GatePlacement(type: .cnotControl(target: 3), qubit: 2, xPosition: 0.50),
        GatePlacement(type: .cnotTarget, qubit: 3, xPosition: 0.50),
        GatePlacement(type: .y, qubit: 4, xPosition: 0.50),

        GatePlacement(type: .z, qubit: 1, xPosition: 0.55),
        GatePlacement(type: .t, qubit: 3, xPosition: 0.55),
        GatePlacement(type: .h, qubit: 0, xPosition: 0.55),

        GatePlacement(type: .cnotControl(target: 1), qubit: 4, xPosition: 0.60),
        GatePlacement(type: .cnotTarget, qubit: 1, xPosition: 0.60),

        GatePlacement(type: .t, qubit: 0, xPosition: 0.65),
        GatePlacement(type: .x, qubit: 1, xPosition: 0.65),
        GatePlacement(type: .h, qubit: 3, xPosition: 0.65),
        GatePlacement(type: .s, qubit: 2, xPosition: 0.65),

        GatePlacement(type: .cnotControl(target: 2), qubit: 1, xPosition: 0.70),
        GatePlacement(type: .cnotTarget, qubit: 2, xPosition: 0.70),
        GatePlacement(type: .z, qubit: 4, xPosition: 0.70),

        GatePlacement(type: .s, qubit: 1, xPosition: 0.75),
        GatePlacement(type: .t, qubit: 2, xPosition: 0.75),
        GatePlacement(type: .y, qubit: 0, xPosition: 0.75),

        GatePlacement(type: .h, qubit: 4, xPosition: 0.80),
        GatePlacement(type: .x, qubit: 3, xPosition: 0.80),
        GatePlacement(type: .z, qubit: 0, xPosition: 0.80),

        GatePlacement(type: .cnotControl(target: 4), qubit: 3, xPosition: 0.85),
        GatePlacement(type: .cnotTarget, qubit: 4, xPosition: 0.85),
        GatePlacement(type: .t, qubit: 1, xPosition: 0.85),

        GatePlacement(type: .h, qubit: 0, xPosition: 0.90),
        GatePlacement(type: .h, qubit: 1, xPosition: 0.90),
        GatePlacement(type: .h, qubit: 2, xPosition: 0.90),
        GatePlacement(type: .h, qubit: 3, xPosition: 0.90),
        GatePlacement(type: .h, qubit: 4, xPosition: 0.90),
    ]

    private let cnotConnections: [(control: Int, target: Int, xPos: CGFloat)] = [
        (0, 1, 0.10),
        (0, 2, 0.20),
        (0, 3, 0.30),
        (0, 4, 0.40),
        (2, 3, 0.50),
        (4, 1, 0.60),
        (1, 2, 0.70),
        (3, 4, 0.85),
    ]

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported.")
    }

    public func startLoopingAnimation(duration: TimeInterval = 20.0, opacity: Float = 0.3) {
        containerLayer?.removeFromSuperlayer()
        wireLayers.removeAll()
        gateLayers.removeAll()
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let mainContainer = CALayer()
        mainContainer.frame = bounds
        mainContainer.opacity = opacity
        layer.addSublayer(mainContainer)
        containerLayer = mainContainer

        wireSpacing = bounds.height / CGFloat(qubitCount + 1)

        let circuitWidth = bounds.width * 2.0

        let layer1 = makeSingleCircuitLayer(width: circuitWidth)
        let layer2 = makeSingleCircuitLayer(width: circuitWidth)

        layer1.frame = CGRect(x: 0, y: 0, width: circuitWidth, height: bounds.height)
        layer2.frame = CGRect(x: circuitWidth, y: 0, width: circuitWidth, height: bounds.height)

        mainContainer.addSublayer(layer1)
        mainContainer.addSublayer(layer2)

        let moveLeft = CABasicAnimation(keyPath: "position.x")
        moveLeft.byValue = -circuitWidth
        moveLeft.duration = duration
        moveLeft.repeatCount = .infinity
        moveLeft.timingFunction = CAMediaTimingFunction(name: .linear)
        moveLeft.isRemovedOnCompletion = false

        layer1.add(moveLeft, forKey: "loop")
        layer2.add(moveLeft, forKey: "loop")
    }

    private func makeSingleCircuitLayer(width: CGFloat) -> CALayer {
        let container = CALayer()
        container.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)

        drawWires(in: container, width: width)
        placeGates(in: container, width: width)
        drawCNOTConnections(in: container, width: width)

        return container
    }

    private func scheduleGatePassCallbacks(duration: TimeInterval) {
        let gateCount = 8
        let interval = duration / Double(gateCount + 1)

        for i in 0..<gateCount {
            let delay = 0.2 + interval * Double(i + 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.onGatePassCenter?(i)
            }
        }
    }

    private func drawQubitLabels(in container: CALayer) {
        for i in 0..<qubitCount {
            let y = wireSpacing * CGFloat(i + 1)

            let textLayer = CATextLayer()
            textLayer.string = "|0⟩"
            textLayer.fontSize = 20
            textLayer.font = UIFont(name: "Menlo", size: 20)
            textLayer.foregroundColor = UIColor.white.withAlphaComponent(0.8).cgColor
            textLayer.alignmentMode = .right
            textLayer.frame = CGRect(x: 5, y: y - 14, width: 45, height: 28)
            textLayer.contentsScale = traitCollection.displayScale

            container.addSublayer(textLayer)
        }
    }

    private func drawWires(in container: CALayer, width: CGFloat) {
        for i in 0..<qubitCount {
            let y = wireSpacing * CGFloat(i + 1)

            let path = UIBezierPath()
            path.move(to: CGPoint(x: 55, y: y))
            path.addLine(to: CGPoint(x: width, y: y))

            let wireLayer = CAShapeLayer()
            wireLayer.path = path.cgPath
            wireLayer.strokeColor = Self.wireColor.cgColor
            wireLayer.lineWidth = 2.5
            wireLayer.lineCap = .round

            container.addSublayer(wireLayer)
            wireLayers.append(wireLayer)
        }
    }

    private func placeGates(in container: CALayer, width: CGFloat) {
        for placement in circuitLayout {
            let x = width * placement.xPosition
            let y = wireSpacing * CGFloat(placement.qubit + 1)

            let gateLayer = createGateLayer(type: placement.type, at: CGPoint(x: x, y: y))
            container.addSublayer(gateLayer)
            gateLayers.append(gateLayer)
        }
    }

    private func createGateLayer(type: GateType, at position: CGPoint) -> CALayer {
        switch type {
        case .cnotControl:
            return createControlDot(at: position)
        case .cnotTarget:
            return createTargetSymbol(at: position)
        default:
            return createGateBox(symbol: type.symbol, at: position)
        }
    }

    private func createGateBox(symbol: String, at position: CGPoint) -> CALayer {
        let size = gateSize

        let container = CALayer()
        container.frame = CGRect(
            x: position.x - size / 2,
            y: position.y - size / 2,
            width: size,
            height: size
        )

        let background = CAShapeLayer()
        background.path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size, height: size), cornerRadius: 6).cgPath
        background.fillColor = Self.gateBackgroundColor.cgColor
        background.strokeColor = Self.gateColor.cgColor
        background.lineWidth = 2
        container.addSublayer(background)

        let textLayer = CATextLayer()
        textLayer.string = symbol
        textLayer.fontSize = 24
        textLayer.font = UIFont(name: "Menlo-Bold", size: 24)
        textLayer.foregroundColor = Self.gateColor.cgColor
        textLayer.alignmentMode = .center
        textLayer.frame = CGRect(x: 0, y: (size - 28) / 2, width: size, height: 28)
        textLayer.contentsScale = traitCollection.displayScale
        container.addSublayer(textLayer)

        return container
    }

    private func createControlDot(at position: CGPoint) -> CALayer {
        let size: CGFloat = 16

        let dotLayer = CAShapeLayer()
        dotLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).cgPath
        dotLayer.fillColor = Self.controlColor.cgColor
        dotLayer.frame = CGRect(
            x: position.x - size / 2,
            y: position.y - size / 2,
            width: size,
            height: size
        )

        return dotLayer
    }

    private func createTargetSymbol(at position: CGPoint) -> CALayer {
        let size: CGFloat = 32

        let container = CALayer()
        container.frame = CGRect(
            x: position.x - size / 2,
            y: position.y - size / 2,
            width: size,
            height: size
        )

        let circle = CAShapeLayer()
        circle.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).cgPath
        circle.fillColor = UIColor.clear.cgColor
        circle.strokeColor = Self.controlColor.cgColor
        circle.lineWidth = 2.5
        container.addSublayer(circle)

        let horizontalPath = UIBezierPath()
        horizontalPath.move(to: CGPoint(x: 0, y: size / 2))
        horizontalPath.addLine(to: CGPoint(x: size, y: size / 2))

        let horizontal = CAShapeLayer()
        horizontal.path = horizontalPath.cgPath
        horizontal.strokeColor = Self.controlColor.cgColor
        horizontal.lineWidth = 2.5
        container.addSublayer(horizontal)

        let verticalPath = UIBezierPath()
        verticalPath.move(to: CGPoint(x: size / 2, y: 0))
        verticalPath.addLine(to: CGPoint(x: size / 2, y: size))

        let vertical = CAShapeLayer()
        vertical.path = verticalPath.cgPath
        vertical.strokeColor = Self.controlColor.cgColor
        vertical.lineWidth = 2.5
        container.addSublayer(vertical)

        return container
    }

    private func drawCNOTConnections(in container: CALayer, width: CGFloat) {
        for pair in cnotConnections {
            let x = width * pair.xPos
            let y1 = wireSpacing * CGFloat(pair.control + 1)
            let y2 = wireSpacing * CGFloat(pair.target + 1)

            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: y1))
            path.addLine(to: CGPoint(x: x, y: y2))

            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = Self.controlColor.cgColor
            lineLayer.lineWidth = 2.5
            lineLayer.lineCap = .round

            container.addSublayer(lineLayer)
        }
    }
}
