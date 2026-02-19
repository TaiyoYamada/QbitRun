
import UIKit
import SwiftUI
import SceneKit

@MainActor
public final class BlochSphereView: UIView {

    private var scnView: SCNView!
    private var scene: SCNScene!
    private var cameraNode: SCNNode!
    private var rootNode: SCNNode!

    private var sphereNode: SCNNode!
    private var axesNode: SCNNode!
    private var gridNode: SCNNode!

    private var coordinator: BlochSphereRenderCoordinator!

    private var cameraYaw: Float = 0.5
    private var cameraPitch: Float = 0.35
    private let cameraDistance: Float = 3.5

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

    public var isInteractive: Bool = true

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
            updateAxesOpacity()
        }
    }

    public var showAxes: Bool = true {
        didSet {
            axesNode?.isHidden = !showAxes
            updateAxesVisibility()
        }
    }

    public var showAxisLabels: Bool = true {
        didSet {
            updateAxesVisibility()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupScene()
        setupGestures()
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

        NSLayoutConstraint.activate([
            scnView.topAnchor.constraint(equalTo: topAnchor, constant: backgroundPadding),
            scnView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -backgroundPadding),
            scnView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: backgroundPadding),
            scnView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -backgroundPadding)
        ])

        scene = SCNScene()
        scnView.scene = scene

        rootNode = SCNNode()
        scene.rootNode.addChildNode(rootNode)

        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        rootNode.addChildNode(cameraNode)

        updateCameraPosition()

        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 800
        scene.rootNode.addChildNode(ambientLight)

        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 1000
        directionalLight.position = SCNVector3(5, 5, 5)
        scene.rootNode.addChildNode(directionalLight)

        createSphereGeometry()
        createGridGeometry()
        createAxesGeometry()

        let stateVectorNode = createArrow(color: UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0), opacity: 1.0)
        stateVectorNode.isHidden = true
        scene.rootNode.addChildNode(stateVectorNode)

        let ghostVectorNode = createArrow(color: UIColor.white, opacity: 1.0)
        ghostVectorNode.isHidden = true
        scene.rootNode.addChildNode(ghostVectorNode)

        coordinator = BlochSphereRenderCoordinator {
        }
        coordinator.stateVectorNode = stateVectorNode
        coordinator.ghostVectorNode = ghostVectorNode

        scnView.delegate = coordinator

        updateBackgroundColor()
    }

    private func createArrow(color: UIColor, opacity: CGFloat) -> SCNNode {
        let container = SCNNode()

        let material = SCNMaterial()
        material.lightingModel = .phong
        material.diffuse.contents = color
        material.specular.contents = UIColor.white
        material.shininess = 30
        material.transparency = opacity

        let headLength: CGFloat = 0.15
        let shaftLength: CGFloat = 1.0 - headLength

        let cylinder = SCNCylinder(radius: 0.025, height: shaftLength)
        cylinder.firstMaterial = material
        let cylNode = SCNNode(geometry: cylinder)
        cylNode.position = SCNVector3(0, shaftLength / 2, 0)
        container.addChildNode(cylNode)

        let cone = SCNCone(topRadius: 0, bottomRadius: 0.05, height: headLength)
        cone.firstMaterial = material
        let coneNode = SCNNode(geometry: cone)
        coneNode.position = SCNVector3(0, shaftLength + headLength / 2, 0)
        container.addChildNode(coneNode)

        return container
    }

    private func updateCameraPosition() {
        let x = cameraDistance * cos(cameraPitch) * sin(cameraYaw)
        let y = cameraDistance * sin(cameraPitch)
        let z = cameraDistance * cos(cameraPitch) * cos(cameraYaw)

        cameraNode.position = SCNVector3(x, y, z)

        let lookAtConstraint = SCNLookAtConstraint(target: scene.rootNode)
        lookAtConstraint.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAtConstraint]
    }

    private func createSphereGeometry() {
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 96

        let material = SCNMaterial()
        material.lightingModel = .phong
        material.diffuse.contents = UIColor(white: 0.95, alpha: 0.1)
        material.specular.contents = UIColor.white
        material.shininess = 50
        material.transparency = 0.15
        material.isDoubleSided = false
        material.cullMode = .back
        material.blendMode = .alpha
        material.fresnelExponent = 1.2

        let fresnelShader = """
        float3 view = normalize(_surface.view);
        float3 normal = normalize(_surface.normal);
        float fresnel = 1.0 - max(0.0, dot(view, normal));
        fresnel = pow(fresnel, 2.0);
        _surface.diffuse.a = _surface.diffuse.a + fresnel * 0.4;
        """
        material.shaderModifiers = [.surface: fresnelShader]

        sphere.firstMaterial = material

        sphereNode = SCNNode(geometry: sphere)
        sphereNode.renderingOrder = 2000
        scene.rootNode.addChildNode(sphereNode)
    }

    private func createGridGeometry() {
        gridNode = SCNNode()
        let gridColor = UIColor(white: 0.6, alpha: 0.4)
        let equatorColor = UIColor(white: 0.4, alpha: 0.6)
        let radius: Float = 1.0

        let pipeRadius: CGFloat = 0.0015

        let latitudeCount = 8
        for i in 1..<latitudeCount {
            let theta = Float(i) * .pi / Float(latitudeCount)
            let r = radius * sin(theta)
            let y = radius * cos(theta)
            let color = (i == latitudeCount / 2) ? equatorColor : gridColor

            let circle = SCNTorus(ringRadius: CGFloat(r), pipeRadius: pipeRadius)
            circle.ringSegmentCount = 72
            circle.pipeSegmentCount = 8

            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.diffuse.contents = color
            circle.firstMaterial = mat

            let node = SCNNode(geometry: circle)
            node.position = SCNVector3(0, y, 0)
            gridNode.addChildNode(node)
        }

        let longitudeCount = 12
        for i in 0..<longitudeCount {
            let phi = Float(i) * .pi / Float(longitudeCount / 2)

            let circle = SCNTorus(ringRadius: CGFloat(radius), pipeRadius: pipeRadius)
            circle.ringSegmentCount = 72
            circle.pipeSegmentCount = 8

            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.diffuse.contents = gridColor
            circle.firstMaterial = mat

            let node = SCNNode(geometry: circle)
            node.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)

            let pivot = SCNNode()
            pivot.eulerAngles = SCNVector3(0, phi, 0)
            pivot.addChildNode(node)

            gridNode.addChildNode(pivot)
        }
        scene.rootNode.addChildNode(gridNode)
    }

    private func createAxesGeometry() {
        axesNode = SCNNode()
        let axisLength: CGFloat = 1.35
        let radius: CGFloat = 0.006
        let labelDistance: CGFloat = 1.6

        let axes: [(SCNVector3, UIColor, String, SCNVector3)] = [
            (SCNVector3(0, 1, 0), BlochAxisPalette.zAxisUIColor, "|0⟩", SCNVector3(0, labelDistance, 0)),
            (SCNVector3(0, -1, 0), BlochAxisPalette.zAxisUIColor, "|1⟩", SCNVector3(0, -labelDistance, 0)),

            (SCNVector3(0, 0, 1), BlochAxisPalette.xAxisUIColor, "|+⟩", SCNVector3(0, 0, labelDistance)),
            (SCNVector3(0, 0, -1), BlochAxisPalette.xAxisUIColor, "|-⟩", SCNVector3(0, 0, -labelDistance)),

            (SCNVector3(1, 0, 0), BlochAxisPalette.yAxisUIColor, "|+i⟩", SCNVector3(labelDistance, 0, 0)),
            (SCNVector3(-1, 0, 0), BlochAxisPalette.yAxisUIColor, "|-i⟩", SCNVector3(-labelDistance, 0, 0))
        ]

        for (dir, color, labelText, labelPos) in axes {
            let cylinder = SCNCylinder(radius: radius, height: axisLength)
            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.diffuse.contents = color
            cylinder.firstMaterial = mat

            let lineNode = SCNNode(geometry: cylinder)
            lineNode.position = SCNVector3(0, axisLength / 2.0, 0)

            let shaftContainer = SCNNode()
            shaftContainer.addChildNode(lineNode)

            if dir.y > 0.9 {
            } else if dir.y < -0.9 {
                shaftContainer.eulerAngles = SCNVector3(Float.pi, 0, 0)
            } else if dir.x > 0.9 {
                shaftContainer.eulerAngles = SCNVector3(0, 0, -Float.pi / 2)
            } else if dir.x < -0.9 {
                shaftContainer.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            } else if dir.z > 0.9 {
                shaftContainer.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            } else if dir.z < -0.9 {
                shaftContainer.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            }

            if (dir.x + dir.y + dir.z) > 0.5 {
                let cone = SCNCone(topRadius: 0, bottomRadius: 0.03, height: 0.12)
                let coneMat = SCNMaterial()
                coneMat.lightingModel = .constant
                coneMat.diffuse.contents = color
                cone.firstMaterial = coneMat

                let coneNode = SCNNode(geometry: cone)
                coneNode.position = SCNVector3(0, axisLength, 0)

                shaftContainer.addChildNode(coneNode)
            }

            axesNode.addChildNode(shaftContainer)

            let textNode = createAxisLabelNode(text: labelText, color: color)
            textNode.position = labelPos
            axesNode.addChildNode(textNode)
        }
        scene.rootNode.addChildNode(axesNode)
    }

    private func createAxisLabelNode(text: String, color: UIColor) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.0)
        if let descriptor = UIFont.systemFont(ofSize: 10, weight: .bold).fontDescriptor.withDesign(.rounded) {
             textGeometry.font = UIFont(descriptor: descriptor, size: 10)
        } else {
             textGeometry.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        }
        textGeometry.flatness = 0.1

        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        material.isDoubleSided = true
        textGeometry.firstMaterial = material

        let node = SCNNode(geometry: textGeometry)
        node.name = "axisLabel"

        let scale: Float = 0.02
        node.scale = SCNVector3(scale, scale, scale)

        let (min, max) = node.boundingBox
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)

        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .all
        node.constraints = [billboard]

        return node
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

        if let axes = axesNode {
            for child in axes.childNodes {
                if child.name == "axisLabel" {
                    child.isHidden = !showAxisLabels
                }
            }
        }
    }

    private func updateAxesOpacity() {
        axesNode?.opacity = axisOpacity
    }

    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isInteractive else { return }

        let translation = gesture.translation(in: self)
        let sensitivity: Float = 0.01

        cameraYaw -= Float(translation.x) * sensitivity
        cameraPitch += Float(translation.y) * sensitivity

        cameraPitch = max(-Float.pi / 2 + 0.1, min(Float.pi / 2 - 0.1, cameraPitch))

        updateCameraPosition()
        gesture.setTranslation(.zero, in: self)
    }
}

private class BlochSphereRenderCoordinator: NSObject, SCNSceneRendererDelegate {

    private let lock = NSLock()

    weak var stateVectorNode: SCNNode?
    weak var ghostVectorNode: SCNNode?

    private var currentBlochVector: BlochVector = .zero
    private var animatingToVector: BlochVector?
    private var animationProgress: Float = 1.0
    private var continuousOrbitAnimation: Bool = false
    private var orbitPhase: Double = 0.0

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
        }
    }

    func setTargetVector(_ vector: BlochVector?) {
        lock.lock()
        defer { lock.unlock() }

        if let v = vector {
            updateVectorNode(ghostVectorNode, vector: v)
        } else {
            ghostVectorNode?.isHidden = true
        }
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
}

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
        view.setTargetVector(targetVector)
        view.setVector(vector, animated: animated)
        view.axisOpacity = axisOpacity
    }
}
