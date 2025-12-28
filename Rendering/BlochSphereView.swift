// SPDX-License-Identifier: MIT
// Rendering/BlochSphereView.swift
// Metal（GPU）を使った論文風ブロッホ球レンダリング

import UIKit
import SwiftUI
import MetalKit
import simd

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 論文風ブロッホ球
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// 特徴:
// - 透明な球体（塗りつぶしなし）
// - 経緯線（グリッド）表示
// - X/Y/Z軸とラベル
// - 状態ベクトル（シアン）
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - シェーダーで使う構造体

struct BlochVertex {
    var position: simd_float3
    var normal: simd_float3
    var color: simd_float4
}

struct BlochUniforms {
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var normalMatrix: simd_float3x3
    var lightDirection: simd_float3
    var cameraPosition: simd_float3
}

// MARK: - BlochSphereView

@MainActor
public final class BlochSphereView: UIView {
    
    // MARK: - Metal関連プロパティ
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    private var linePipeline: MTLRenderPipelineState?
    private var depthState: MTLDepthStencilState?
    private var metalView: MTKView?
    private var renderDelegate: BlochRenderDelegate?
    
    // MARK: - ジオメトリデータ
    
    private var gridVertexBuffer: MTLBuffer?
    private var gridVertexCount: Int = 0
    private var axisVertexBuffer: MTLBuffer?
    private var axisVertexCount: Int = 0
    private var stateVectorBuffer: MTLBuffer?
    private var stateVectorVertexCount: Int = 0
    private var uniformBuffer: MTLBuffer?
    
    // MARK: - 表示状態
    
    private var currentBlochVector: BlochVector = .zero
    private var targetBlochVector: BlochVector?
    private var animationProgress: Float = 1.0
    private var cameraYaw: Float = 0.5
    private var cameraPitch: Float = 0.35
    
    // MARK: - 初期化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupMetal()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未実装です")
    }
    
    // MARK: - セットアップ
    
    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        commandQueue = device.makeCommandQueue()
        
        let metalView = MTKView(frame: bounds, device: device)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.preferredFramesPerSecond = 60
        addSubview(metalView)
        self.metalView = metalView
        
        NSLayoutConstraint.activate([
            metalView.topAnchor.constraint(equalTo: topAnchor),
            metalView.bottomAnchor.constraint(equalTo: bottomAnchor),
            metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        setupPipelines(device: device)
        setupDepthState(device: device)
        createGeometry(device: device)
        uniformBuffer = device.makeBuffer(length: MemoryLayout<BlochUniforms>.size, options: .storageModeShared)
        
        renderDelegate = BlochRenderDelegate(view: self)
        metalView.delegate = renderDelegate
    }
    
    private func setupPipelines(device: MTLDevice) {
        guard let library = device.makeDefaultLibrary() else { return }
        
        // ライン用パイプライン（グリッド、軸、ベクトル全て）
        if let vertexFunc = library.makeFunction(name: "lineVertexShader"),
           let fragmentFunc = library.makeFunction(name: "lineFragmentShader") {
            let desc = MTLRenderPipelineDescriptor()
            desc.vertexFunction = vertexFunc
            desc.fragmentFunction = fragmentFunc
            desc.colorAttachments[0].pixelFormat = .bgra8Unorm
            desc.depthAttachmentPixelFormat = .depth32Float
            desc.colorAttachments[0].isBlendingEnabled = true
            desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            linePipeline = try? device.makeRenderPipelineState(descriptor: desc)
        }
    }
    
    private func setupDepthState(device: MTLDevice) {
        let desc = MTLDepthStencilDescriptor()
        desc.depthCompareFunction = .less
        desc.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: desc)
    }
    
    // MARK: - ジオメトリ作成
    
    private func createGeometry(device: MTLDevice) {
        createGridGeometry(device: device)
        createAxisGeometry(device: device)
        updateStateVectorBuffer(vector: .zero)
    }
    
    /// グリッド（経緯線）を作成
    private func createGridGeometry(device: MTLDevice) {
        var vertices: [BlochVertex] = []
        let radius: Float = 1.0
        let gridColor = simd_float4(0.6, 0.6, 0.65, 0.6)  // 薄い灰色
        let equatorColor = simd_float4(0.4, 0.4, 0.45, 0.8)  // やや濃い灰色
        
        // 緯線（latitude circles）
        let latitudeCount = 8
        for i in 1..<latitudeCount {
            let theta = Float(i) * .pi / Float(latitudeCount)
            let r = radius * sin(theta)
            let z = radius * cos(theta)
            let color = (i == latitudeCount / 2) ? equatorColor : gridColor
            
            let segments = 64
            for j in 0..<segments {
                let phi1 = Float(j) * 2 * .pi / Float(segments)
                let phi2 = Float(j + 1) * 2 * .pi / Float(segments)
                
                let p1 = simd_float3(r * cos(phi1), r * sin(phi1), z)
                let p2 = simd_float3(r * cos(phi2), r * sin(phi2), z)
                
                vertices.append(BlochVertex(position: p1, normal: normalize(p1), color: color))
                vertices.append(BlochVertex(position: p2, normal: normalize(p2), color: color))
            }
        }
        
        // 経線（longitude circles）
        let longitudeCount = 12
        for i in 0..<longitudeCount {
            let phi = Float(i) * .pi / Float(longitudeCount / 2)
            
            let segments = 64
            for j in 0..<segments {
                let theta1 = Float(j) * .pi / Float(segments)
                let theta2 = Float(j + 1) * .pi / Float(segments)
                
                let p1 = simd_float3(radius * sin(theta1) * cos(phi), radius * sin(theta1) * sin(phi), radius * cos(theta1))
                let p2 = simd_float3(radius * sin(theta2) * cos(phi), radius * sin(theta2) * sin(phi), radius * cos(theta2))
                
                vertices.append(BlochVertex(position: p1, normal: normalize(p1), color: gridColor))
                vertices.append(BlochVertex(position: p2, normal: normalize(p2), color: gridColor))
            }
        }
        
        // 外周円（XY平面の赤道）
        let outerCircleColor = simd_float4(0.3, 0.3, 0.35, 0.9)
        let outerSegments = 128
        for j in 0..<outerSegments {
            let phi1 = Float(j) * 2 * .pi / Float(outerSegments)
            let phi2 = Float(j + 1) * 2 * .pi / Float(outerSegments)
            
            let p1 = simd_float3(radius * cos(phi1), radius * sin(phi1), 0)
            let p2 = simd_float3(radius * cos(phi2), radius * sin(phi2), 0)
            
            vertices.append(BlochVertex(position: p1, normal: simd_float3(0, 0, 1), color: outerCircleColor))
            vertices.append(BlochVertex(position: p2, normal: simd_float3(0, 0, 1), color: outerCircleColor))
        }
        
        gridVertexCount = vertices.count
        gridVertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<BlochVertex>.stride, options: .storageModeShared)
    }
    
    private func createAxisGeometry(device: MTLDevice) {
        var vertices: [BlochVertex] = []
        let axisLength: Float = 1.3
        
        // X軸（濃い赤）
        let xColor = simd_float4(0.8, 0.2, 0.2, 1)
        vertices.append(BlochVertex(position: simd_float3(-axisLength, 0, 0), normal: simd_float3(1, 0, 0), color: xColor))
        vertices.append(BlochVertex(position: simd_float3(axisLength, 0, 0), normal: simd_float3(1, 0, 0), color: xColor))
        
        // Y軸（濃い緑）
        let yColor = simd_float4(0.2, 0.7, 0.2, 1)
        vertices.append(BlochVertex(position: simd_float3(0, -axisLength, 0), normal: simd_float3(0, 1, 0), color: yColor))
        vertices.append(BlochVertex(position: simd_float3(0, axisLength, 0), normal: simd_float3(0, 1, 0), color: yColor))
        
        // Z軸（濃い青）
        let zColor = simd_float4(0.2, 0.3, 0.8, 1)
        vertices.append(BlochVertex(position: simd_float3(0, 0, -axisLength), normal: simd_float3(0, 0, 1), color: zColor))
        vertices.append(BlochVertex(position: simd_float3(0, 0, axisLength), normal: simd_float3(0, 0, 1), color: zColor))
        
        axisVertexCount = vertices.count
        axisVertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<BlochVertex>.stride, options: .storageModeShared)
    }
    
    private func updateStateVectorBuffer(vector: BlochVector) {
        guard let device = device else { return }
        
        var vertices: [BlochVertex] = []
        let vectorColor = simd_float4(0.1, 0.6, 0.8, 1)  // 濃いシアン
        let target = vector.float3
        
        // 原点から状態ベクトルへの線
        vertices.append(BlochVertex(position: simd_float3(0, 0, 0), normal: target, color: vectorColor))
        vertices.append(BlochVertex(position: target, normal: target, color: vectorColor))
        
        stateVectorVertexCount = vertices.count
        stateVectorBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<BlochVertex>.stride, options: .storageModeShared)
    }
    
    // MARK: - 公開メソッド
    
    public func setVector(_ vector: BlochVector, animated: Bool) {
        if animated && animationProgress >= 1.0 {
            targetBlochVector = vector
            animationProgress = 0.0
        } else {
            currentBlochVector = vector
            targetBlochVector = nil
            animationProgress = 1.0
            updateStateVectorBuffer(vector: vector)
        }
    }
    
    // MARK: - 描画
    
    func draw(in view: MTKView) {
        // アニメーション更新
        if let target = targetBlochVector, animationProgress < 1.0 {
            animationProgress += 0.08
            if animationProgress >= 1.0 {
                animationProgress = 1.0
                currentBlochVector = target
                targetBlochVector = nil
            } else {
                let t = animationProgress
                let currentV = currentBlochVector.vector * Double(1 - t)
                let targetV = target.vector * Double(t)
                currentBlochVector = BlochVector(currentV + targetV)
            }
            updateStateVectorBuffer(vector: currentBlochVector)
        }
        
        guard let commandBuffer = commandQueue?.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let drawable = view.currentDrawable else { return }
        
        updateUniforms(viewSize: view.drawableSize)
        encoder.setDepthStencilState(depthState)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        
        // グリッドを描画
        if let pipeline = linePipeline, let buffer = gridVertexBuffer {
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: gridVertexCount)
        }
        
        // 軸を描画
        if let pipeline = linePipeline, let buffer = axisVertexBuffer {
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: axisVertexCount)
        }
        
        // 状態ベクトルを描画
        if let pipeline = linePipeline, let buffer = stateVectorBuffer {
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: stateVectorVertexCount)
        }
        
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func updateUniforms(viewSize: CGSize) {
        let modelMatrix = matrix_identity_float4x4
        
        let cameraDistance: Float = 3.2
        let cameraX = cameraDistance * cos(cameraPitch) * sin(cameraYaw)
        let cameraY = cameraDistance * sin(cameraPitch)
        let cameraZ = cameraDistance * cos(cameraPitch) * cos(cameraYaw)
        let cameraPosition = simd_float3(cameraX, cameraY, cameraZ)
        let viewMatrix = lookAt(eye: cameraPosition, center: simd_float3(0, 0, 0), up: simd_float3(0, 0, 1))
        
        let aspect = Float(viewSize.width / viewSize.height)
        let projectionMatrix = perspective(fovyRadians: .pi / 4, aspect: aspect, nearZ: 0.1, farZ: 100)
        
        let normalMatrix = simd_float3x3(
            simd_float3(modelMatrix.columns.0.x, modelMatrix.columns.0.y, modelMatrix.columns.0.z),
            simd_float3(modelMatrix.columns.1.x, modelMatrix.columns.1.y, modelMatrix.columns.1.z),
            simd_float3(modelMatrix.columns.2.x, modelMatrix.columns.2.y, modelMatrix.columns.2.z)
        )
        
        var uniforms = BlochUniforms(
            modelMatrix: modelMatrix,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix,
            normalMatrix: normalMatrix,
            lightDirection: normalize(simd_float3(1, 1, 1)),
            cameraPosition: cameraPosition
        )
        
        uniformBuffer?.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<BlochUniforms>.size)
    }
    
    // MARK: - 行列計算ヘルパー
    
    private func lookAt(eye: simd_float3, center: simd_float3, up: simd_float3) -> simd_float4x4 {
        let z = normalize(eye - center)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        return simd_float4x4(
            simd_float4(x.x, y.x, z.x, 0),
            simd_float4(x.y, y.y, z.y, 0),
            simd_float4(x.z, y.z, z.z, 0),
            simd_float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
        )
    }
    
    private func perspective(fovyRadians: Float, aspect: Float, nearZ: Float, farZ: Float) -> simd_float4x4 {
        let ys = 1 / tan(fovyRadians * 0.5)
        let xs = ys / aspect
        let zs = farZ / (nearZ - farZ)
        return simd_float4x4(
            simd_float4(xs, 0, 0, 0),
            simd_float4(0, ys, 0, 0),
            simd_float4(0, 0, zs, -1),
            simd_float4(0, 0, zs * nearZ, 0)
        )
    }
}

// MARK: - 描画デリゲート

private final class BlochRenderDelegate: NSObject, MTKViewDelegate {
    private weak var view: BlochSphereView?
    
    init(view: BlochSphereView) {
        self.view = view
        super.init()
    }
    
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    nonisolated func draw(in mtkView: MTKView) {
        let blochView = self.view
        Task { @MainActor in
            blochView?.draw(in: mtkView)
        }
    }
}

// MARK: - SwiftUI連携

struct BlochSphereViewRepresentable: UIViewRepresentable {
    var vector: BlochVector
    var animated: Bool
    
    func makeUIView(context: Context) -> BlochSphereView {
        BlochSphereView()
    }
    
    func updateUIView(_ uiView: BlochSphereView, context: Context) {
        uiView.setVector(vector, animated: animated)
    }
}

// MARK: - プレビュー

#Preview("ブロッホ球 - |0⟩") {
    BlochSphereViewRepresentable(vector: .zero, animated: false)
        .frame(width: 600, height: 600)
}
//
//#Preview("ブロッホ球 - |1⟩") {
//    BlochSphereViewRepresentable(vector: BlochVector(simd_double3(0, 0, -1)), animated: false)
//        .frame(width: 400, height: 400)
//        .background(Color.black)
//}
//
//#Preview("ブロッホ球 - |+⟩") {
//    BlochSphereViewRepresentable(vector: BlochVector(simd_double3(1, 0, 0)), animated: false)
//        .frame(width: 400, height: 400)
//        .background(Color.black)
//}
