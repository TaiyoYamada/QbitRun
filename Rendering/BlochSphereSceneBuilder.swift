import UIKit
import SceneKit

/// ブロッホ球の3Dシーン（球体・グリッド・軸・カメラ・ライティング）を構築するビルダー
@MainActor
public final class BlochSphereSceneBuilder {

    private typealias AxisDefinition = (
        direction: SCNVector3, color: UIColor,
        labelText: String, labelPosition: SCNVector3
    )


    public func buildScene(
        in scene: SCNScene,
        backgroundPadding: CGFloat,
        showAxisLabels: Bool
    ) -> (sphereNode: SCNNode, gridNode: SCNNode, axesNode: SCNNode, cameraNode: SCNNode) {

        let cameraNode = createCamera(in: scene)
        createLighting(in: scene)

        let sphereNode = createSphere(in: scene)
        let gridNode = createGrid(in: scene)
        let axesNode = createAxes(in: scene, showAxisLabels: showAxisLabels)

        return (sphereNode, gridNode, axesNode, cameraNode)
    }

    public func createArrow(color: UIColor, opacity: CGFloat) -> SCNNode {
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

    public func addAxisLabelsIfNeeded(to axesNode: SCNNode) {
        if axesNode.childNodes.contains(where: { $0.name == "axisLabel" }) {
            return
        }

        for (_, color, labelText, labelPos) in axisDefinitions() {
            let textNode = createAxisLabelNode(text: labelText, color: color)
            textNode.position = labelPos
            axesNode.addChildNode(textNode)
        }
    }


    private func createCamera(in scene: SCNScene) -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        scene.rootNode.addChildNode(cameraNode)
        return cameraNode
    }

    private func createLighting(in scene: SCNScene) {
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
    }

    private func createSphere(in scene: SCNScene) -> SCNNode {
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 48

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

        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.renderingOrder = 2000
        scene.rootNode.addChildNode(sphereNode)
        return sphereNode
    }

    private func createGrid(in scene: SCNScene) -> SCNNode {
        let gridNode = SCNNode()
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
        let sharedLongitudeTorus = SCNTorus(ringRadius: CGFloat(radius), pipeRadius: pipeRadius)
        sharedLongitudeTorus.ringSegmentCount = 72
        sharedLongitudeTorus.pipeSegmentCount = 8

        let sharedLongMat = SCNMaterial()
        sharedLongMat.lightingModel = .constant
        sharedLongMat.diffuse.contents = gridColor
        sharedLongitudeTorus.firstMaterial = sharedLongMat

        for i in 0..<longitudeCount {
            let phi = Float(i) * .pi / Float(longitudeCount / 2)

            let node = SCNNode(geometry: sharedLongitudeTorus)
            node.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)

            let pivot = SCNNode()
            pivot.eulerAngles = SCNVector3(0, phi, 0)
            pivot.addChildNode(node)

            gridNode.addChildNode(pivot)
        }
        scene.rootNode.addChildNode(gridNode)
        return gridNode
    }

    private func createAxes(in scene: SCNScene, showAxisLabels: Bool) -> SCNNode {
        let axesNode = SCNNode()
        let axisLength: CGFloat = 1.35
        let radius: CGFloat = 0.006

        let axes = axisDefinitions()

        for (dir, color, _, _) in axes {
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
        }
        if showAxisLabels {
            addAxisLabelsIfNeeded(to: axesNode)
        }
        scene.rootNode.addChildNode(axesNode)
        return axesNode
    }

    private func axisDefinitions() -> [AxisDefinition] {
        let labelDistance: CGFloat = 1.6
        return [
            (SCNVector3(0, 1, 0), BlochAxisPalette.zAxisUIColor, "|0⟩", SCNVector3(0, labelDistance, 0)),
            (SCNVector3(0, -1, 0), BlochAxisPalette.zAxisUIColor, "|1⟩", SCNVector3(0, -labelDistance, 0)),
            (SCNVector3(0, 0, 1), BlochAxisPalette.xAxisUIColor, "|+⟩", SCNVector3(0, 0, labelDistance)),
            (SCNVector3(0, 0, -1), BlochAxisPalette.xAxisUIColor, "|-⟩", SCNVector3(0, 0, -labelDistance)),
            (SCNVector3(1, 0, 0), BlochAxisPalette.yAxisUIColor, "|+i⟩", SCNVector3(labelDistance, 0, 0)),
            (SCNVector3(-1, 0, 0), BlochAxisPalette.yAxisUIColor, "|-i⟩", SCNVector3(-labelDistance, 0, 0))
        ]
    }

    private func createAxisLabelNode(text: String, color: UIColor) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.0)
        if let descriptor = UIFont.systemFont(ofSize: 11, weight: .bold).fontDescriptor.withDesign(.rounded) {
             textGeometry.font = UIFont(descriptor: descriptor, size: 11)
        } else {
             textGeometry.font = UIFont.systemFont(ofSize: 11, weight: .bold)
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
}
