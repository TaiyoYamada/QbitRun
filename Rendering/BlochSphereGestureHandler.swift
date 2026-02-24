import UIKit
import SceneKit

@MainActor
public final class BlochSphereGestureHandler: NSObject {

    public var isInteractive: Bool = true

    public private(set) var cameraYaw: Float = 0.5
    public private(set) var cameraPitch: Float = 0.35
    public let cameraDistance: Float = 3.5

    public var onCameraUpdated: (() -> Void)?

    public func attachTo(_ view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture)
    }

    public func updateCameraPosition(cameraNode: SCNNode, rootNode: SCNNode) {
        let x = cameraDistance * cos(cameraPitch) * sin(cameraYaw)
        let y = cameraDistance * sin(cameraPitch)
        let z = cameraDistance * cos(cameraPitch) * cos(cameraYaw)

        cameraNode.position = SCNVector3(x, y, z)

        let lookAtConstraint = SCNLookAtConstraint(target: rootNode)
        lookAtConstraint.isGimbalLockEnabled = true
        cameraNode.constraints = [lookAtConstraint]
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isInteractive, let view = gesture.view else { return }

        let translation = gesture.translation(in: view)
        let sensitivity: Float = 0.01

        cameraYaw -= Float(translation.x) * sensitivity
        cameraPitch += Float(translation.y) * sensitivity
        cameraPitch = max(-Float.pi / 2 + 0.1, min(Float.pi / 2 - 0.1, cameraPitch))

        gesture.setTranslation(.zero, in: view)
        onCameraUpdated?()
    }
}
