import UIKit
import SwiftUI
import SceneKit

/// SceneKitを使用してブロッホ球を描画するUIView
@MainActor
public final class BlochSphereView: UIView {

    private var scnView: SCNView!
    private var scene: SCNScene!
    private var cameraNode: SCNNode!

    private var sphereNode: SCNNode!
    private var axesNode: SCNNode!
    private var gridNode: SCNNode!

    private var coordinator: BlochSphereRenderCoordinator!
    private let sceneBuilder = BlochSphereSceneBuilder()
    private let gestureHandler = BlochSphereGestureHandler()

    public var onOrbitStop: ((BlochVector) -> Void)?

    public var continuousOrbitAnimation: Bool = false {
        didSet {
            let wasEnabled = oldValue
            coordinator.setContinuousOrbit(continuousOrbitAnimation)
            if !continuousOrbitAnimation && wasEnabled {
                onOrbitStop?(coordinator.getCurrentVector())
            }
        }
    }

    public var isInteractive: Bool = true {
        didSet {
            gestureHandler.isInteractive = isInteractive
        }
    }

    public var showBackground: Bool = true {
        didSet {
            updateBackgroundColor()
        }
    }

    public var backgroundPadding: CGFloat = 16 {
        didSet {
            updateBackgroundInsets()
        }
    }

    public var axisOpacity: CGFloat = 1.0 {
        didSet {
            axesNode?.opacity = axisOpacity
        }
    }

    public var showAxes: Bool = true {
        didSet {
            axesNode?.isHidden = !showAxes
            updateAxesVisibility()
        }
    }

    public var showAxisLabels: Bool = false {
        didSet {
            updateAxesVisibility()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupScene()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
    }

    private func setupScene() {
        scnView = SCNView(frame: bounds)
        scnView.translatesAutoresizingMaskIntoConstraints = false
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60
        scnView.isPlaying = true
        addSubview(scnView)

        isAccessibilityElement = false
        accessibilityElementsHidden = true
        scnView.isAccessibilityElement = false
        scnView.accessibilityElementsHidden = true

        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: topAnchor, constant: backgroundPadding),
            scnView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -backgroundPadding),
            scnView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: backgroundPadding),
            scnView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -backgroundPadding)
        ])

        scene = SCNScene()
        scnView.scene = scene

        let result = sceneBuilder.buildScene(
            in: scene,
            backgroundPadding: backgroundPadding,
            showAxisLabels: showAxisLabels
        )
        sphereNode = result.sphereNode
        gridNode = result.gridNode
        axesNode = result.axesNode
        cameraNode = result.cameraNode

        let stateVectorNode = sceneBuilder.createArrow(
            color: UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0),
            opacity: 1.0
        )
        stateVectorNode.isHidden = true
        scene.rootNode.addChildNode(stateVectorNode)

        let ghostVectorNode = sceneBuilder.createArrow(color: UIColor.white, opacity: 1.0, defaultTip: .sphere)
        ghostVectorNode.isHidden = true
        scene.rootNode.addChildNode(ghostVectorNode)

        coordinator = BlochSphereRenderCoordinator {}
        coordinator.stateVectorNode = stateVectorNode
        coordinator.ghostVectorNode = ghostVectorNode
        scnView.delegate = coordinator


        gestureHandler.isInteractive = isInteractive
        gestureHandler.onCameraUpdated = { [weak self] in
            self?.updateCameraPosition()
        }
        gestureHandler.attachTo(self)

        updateCameraPosition()
        updateBackgroundColor()
    }

    private func updateCameraPosition() {
        gestureHandler.updateCameraPosition(
            cameraNode: cameraNode,
            rootNode: scene.rootNode
        )
    }

    public func setVector(_ vector: BlochVector, animated: Bool) {
        coordinator.setVector(vector, animated: animated)
    }

    public func setTargetVector(_ vector: BlochVector?) {
        coordinator.setTargetVector(vector)
    }

    private func updateBackgroundColor() {
        if showBackground {
            scnView.backgroundColor = .white
            layer.cornerRadius = 16
            layer.masksToBounds = true
            backgroundColor = .white
        } else {
            scnView.backgroundColor = .clear
            layer.cornerRadius = 0
            layer.masksToBounds = false
            backgroundColor = .clear
        }
    }

    private func updateBackgroundInsets() {
        NSLayoutConstraint.deactivate(scnView.constraints)
        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: topAnchor, constant: backgroundPadding),
            scnView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -backgroundPadding),
            scnView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: backgroundPadding),
            scnView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -backgroundPadding)
        ])
    }

    private func updateAxesVisibility() {
        axesNode?.isHidden = !showAxes

        if showAxisLabels, let axesNode {
            sceneBuilder.addAxisLabelsIfNeeded(to: axesNode)
        }

        if let axes = axesNode {
            for child in axes.childNodes {
                if child.name == "axisLabel" {
                    child.isHidden = !showAxisLabels
                }
            }
        }
    }
}

/// ブロッホ球のレンダリングループを管理するコーディネーター
private class BlochSphereRenderCoordinator: NSObject, SCNSceneRendererDelegate {

    private let lock = NSLock()

    weak var stateVectorNode: SCNNode?
    weak var ghostVectorNode: SCNNode?

    private var currentBlochVector: BlochVector = .zero
    private var currentTargetVector: BlochVector?
    private var animatingToVector: BlochVector?
    private var animationProgress: Float = 1.0
    private var continuousOrbitAnimation: Bool = false
    private var orbitPhase: Double = 0.0
    private var lastIsMatching: Bool?

    let onDidRender: @Sendable () -> Void

    init(onDidRender: @escaping @Sendable () -> Void) {
        self.onDidRender = onDidRender
        super.init()
    }

    func setVector(_ vector: BlochVector, animated: Bool) {
        lock.lock()
        defer { lock.unlock() }

        if animated && animationProgress >= 1.0 {
            animatingToVector = vector
            animationProgress = 0.0
        } else {
            currentBlochVector = vector
            animatingToVector = nil
            animationProgress = 1.0
            updateVectorNode(stateVectorNode, vector: vector)
            lastIsMatching = nil
            updateVectorColorsIfNeeded()
        }
    }

    func setTargetVector(_ vector: BlochVector?) {
        lock.lock()
        defer { lock.unlock() }

        currentTargetVector = vector

        if let v = vector {
            updateVectorNode(ghostVectorNode, vector: v)
        } else {
            ghostVectorNode?.isHidden = true
        }
        lastIsMatching = nil
        updateVectorColorsIfNeeded()
    }

    func setContinuousOrbit(_ enabled: Bool) {
        lock.lock()
        defer { lock.unlock() }
        continuousOrbitAnimation = enabled
    }

    func getCurrentVector() -> BlochVector {
        lock.lock()
        defer { lock.unlock() }
        return currentBlochVector
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        lock.lock()

        if continuousOrbitAnimation {
            orbitPhase += 0.02

            let theta = sin(orbitPhase * 0.7) * .pi * 0.8 + .pi / 2
            let phi = orbitPhase * 1.3

            let x = sin(theta) * cos(phi)
            let y = sin(theta) * sin(phi)
            let z = cos(theta)

            let vec = BlochVector(simd_double3(x, y, z))
            currentBlochVector = vec
            updateVectorNode(stateVectorNode, vector: vec)
            updateVectorColorsIfNeeded()

        } else if let target = animatingToVector, animationProgress < 1.0 {
            animationProgress += 0.02
            if animationProgress >= 1.0 {
                animationProgress = 1.0
                currentBlochVector = target
                animatingToVector = nil
            } else {
                let t = Double(animationProgress)
                let currentV = currentBlochVector.vector * (1.0 - t)
                let targetV = target.vector * t
                currentBlochVector = BlochVector(currentV + targetV)
            }
            updateVectorNode(stateVectorNode, vector: currentBlochVector)
            updateVectorColorsIfNeeded()
        }

        lock.unlock()

        onDidRender()
    }

    private func updateVectorNode(_ node: SCNNode?, vector: BlochVector) {
        guard let node = node else { return }

        let rawV = vector.float3

        let v = simd_float3(rawV.y, rawV.z, rawV.x)

        let length = simd_length(v)

        if length < 0.001 {
            node.isHidden = true
            return
        }
        node.isHidden = false

        let up = simd_float3(0, 1, 0)
        let direction = simd_normalize(v)

        let axis = simd_cross(up, direction)
        let dot = simd_dot(up, direction)

        if simd_length(axis) < 0.001 {
            if dot > 0 {
                node.orientation = SCNQuaternion(0, 0, 0, 1)
            } else {
                node.orientation = SCNQuaternion(1, 0, 0, 0)
            }
        } else {
            let angle = acos(dot)
            let normAxis = simd_normalize(axis)
            node.rotation = SCNVector4(normAxis.x, normAxis.y, normAxis.z, angle)
        }

        node.scale = SCNVector3(1, length, 1)
    }

    private func updateVectorColorsIfNeeded() {
        let isMatching: Bool
        if let target = currentTargetVector {
            let epsilon: Double = 0.1
            isMatching = simd_distance(currentBlochVector.vector, target.vector) < epsilon
        } else {
            isMatching = false
        }

        guard isMatching != lastIsMatching else { return }
        lastIsMatching = isMatching

        applyVectorColors(isMatching: isMatching)
    }

    private func applyVectorColors(isMatching: Bool) {
        guard let stateNode = stateVectorNode else { return }

        let stateColor = isMatching ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) : UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        let targetColor = isMatching ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) : UIColor.white
        let emissionColor = isMatching ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8) : UIColor.black

        for child in stateNode.childNodes {
            if let material = child.geometry?.firstMaterial {
                material.diffuse.contents = stateColor
                material.emission.contents = emissionColor
            }
        }

        if let ghostNode = ghostVectorNode {
            for child in ghostNode.childNodes {
                if let material = child.geometry?.firstMaterial {
                    material.diffuse.contents = targetColor
                    material.emission.contents = emissionColor
                }
            }
        }

        BlochSphereSceneBuilder.setTipShape(isMatching ? .diamond : .cone, on: stateNode)
        if let ghostNode = ghostVectorNode {
            BlochSphereSceneBuilder.setTipShape(isMatching ? .diamond : .sphere, on: ghostNode)
        }
    }
}

/// `BlochSphereView`をSwiftUIで使用するためのUIViewRepresentable
public struct BlochSphereViewRepresentable: UIViewRepresentable {
    public var vector: BlochVector = .zero
    public var targetVector: BlochVector? = nil
    public var showBackground: Bool = true
    public var showAxes: Bool = true
    public var showAxisLabels: Bool = true
    public var continuousOrbitAnimation: Bool = false
    public var backgroundPadding: CGFloat = 16
    public var onOrbitStop: ((BlochVector) -> Void)? = nil
    public var isInteractive: Bool = true
    public var animated: Bool = true
    public var axisOpacity: CGFloat = 1.0

    public init(
        vector: BlochVector = .zero,
        animated: Bool = true,
        targetVector: BlochVector? = nil,
        showBackground: Bool = true,
        showAxes: Bool = true,
        showAxisLabels: Bool = true,
        continuousOrbitAnimation: Bool = false,
        backgroundPadding: CGFloat = 16,
        onOrbitStop: ((BlochVector) -> Void)? = nil,
        isInteractive: Bool = true,
        axisOpacity: CGFloat = 1.0
    ) {
        self.vector = vector
        self.animated = animated
        self.targetVector = targetVector
        self.showBackground = showBackground
        self.showAxes = showAxes
        self.showAxisLabels = showAxisLabels
        self.continuousOrbitAnimation = continuousOrbitAnimation
        self.backgroundPadding = backgroundPadding
        self.onOrbitStop = onOrbitStop
        self.isInteractive = isInteractive
        self.axisOpacity = axisOpacity
    }

    public func makeUIView(context: Context) -> BlochSphereView {
        let view = BlochSphereView()
        updateView(view)
        return view
    }

    public func updateUIView(_ uiView: BlochSphereView, context: Context) {
        updateView(uiView)
    }

    private func updateView(_ view: BlochSphereView) {
        view.showBackground = showBackground
        view.showAxes = showAxes
        view.showAxisLabels = showAxisLabels
        view.continuousOrbitAnimation = continuousOrbitAnimation
        view.backgroundPadding = backgroundPadding
        view.onOrbitStop = onOrbitStop
        view.isInteractive = isInteractive
        view.setTargetVector(targetVector)

        view.setVector(vector, animated: animated)
        view.axisOpacity = axisOpacity
    }
}
