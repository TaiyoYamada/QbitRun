// SPDX-License-Identifier: MIT
// Rendering/MetalBlochSphereView.swift
// Metal（GPU）を使った高品質ブロッホ球レンダリング

import UIKit
import MetalKit
import simd

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Metalとは？
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// AppleのGPUプログラミングAPI（OpenGL ESの後継）
//
// 主要コンポーネント:
// - MTLDevice: GPUデバイスへの参照
// - MTLCommandQueue: 描画コマンドのキュー
// - MTLRenderPipeline: 頂点/フラグメントシェーダーの設定
// - MTLBuffer: GPUに渡す頂点データ等を格納
// - MTKView: Metal描画用のUIView
//
// 描画の流れ:
// 1. MTLCommandBuffer を作成
// 2. MTLRenderCommandEncoder で描画コマンドを積む
// 3. present() で画面に表示
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - シェーダーで使う構造体

/// 頂点データ（GPU用）
/// Metalシェーダーと構造が一致している必要がある
struct Vertex {
    var position: simd_float3  // 位置
    var normal: simd_float3    // 法線（ライティング用）
    var color: simd_float4     // 色
}

/// ユニフォームデータ（毎フレーム更新）
/// カメラ行列やライトの設定など
struct Uniforms {
    var modelMatrix: simd_float4x4       // モデル変換行列
    var viewMatrix: simd_float4x4        // ビュー行列（カメラ）
    var projectionMatrix: simd_float4x4  // 投影行列
    var normalMatrix: simd_float3x3      // 法線変換行列
    var lightDirection: simd_float3      // ライトの方向
    var cameraPosition: simd_float3      // カメラ位置
}

// MARK: - MetalBlochSphereView

/// Metalで3Dブロッホ球を描画するビュー
@MainActor
public final class MetalBlochSphereView: UIView {
    
    // MARK: - Metal関連プロパティ
    
    /// Metalデバイス（GPU）
    private var device: MTLDevice?
    
    /// コマンドキュー
    private var commandQueue: MTLCommandQueue?
    
    /// 球体描画用パイプライン
    private var spherePipeline: MTLRenderPipelineState?
    
    /// ワイヤーフレーム/ベクトル描画用パイプライン
    private var linePipeline: MTLRenderPipelineState?
    
    /// 深度ステンシル状態
    private var depthState: MTLDepthStencilState?
    
    /// Metal描画ビュー
    private var metalView: MTKView?
    
    /// 描画デリゲート
    private var renderDelegate: MetalRenderDelegate?
    
    // MARK: - ジオメトリデータ
    
    /// 球体の頂点バッファ
    private var sphereVertexBuffer: MTLBuffer?
    private var sphereVertexCount: Int = 0
    
    /// 軸線の頂点バッファ
    private var axisVertexBuffer: MTLBuffer?
    private var axisVertexCount: Int = 0
    
    /// 状態ベクトルの頂点バッファ
    private var stateVectorBuffer: MTLBuffer?
    private var stateVectorVertexCount: Int = 0
    
    /// ユニフォームバッファ
    private var uniformBuffer: MTLBuffer?
    
    // MARK: - 表示状態
    
    /// 現在のブロッホベクトル
    private var currentBlochVector: BlochVector = .zero
    
    /// ターゲットベクトル（アニメーション用）
    private var targetBlochVector: BlochVector?
    
    /// アニメーション進捗
    private var animationProgress: Float = 1.0
    
    /// カメラ回転角度
    private var cameraYaw: Float = 0.4
    private var cameraPitch: Float = 0.3
    
    // MARK: - 初期化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupMetal()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未実装です")
    }
    
    // MARK: - セットアップ
    
    /// Metal環境をセットアップ
    private func setupMetal() {
        // 1. デバイス取得
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metalデバイスを作成できませんでした")
            return
        }
        self.device = device
        
        // 2. コマンドキュー作成
        commandQueue = device.makeCommandQueue()
        
        // 3. MTKViewをセットアップ
        let metalView = MTKView(frame: bounds, device: device)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
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
        
        // 4. パイプライン作成
        setupPipelines(device: device)
        
        // 5. 深度テスト設定
        setupDepthState(device: device)
        
        // 6. ジオメトリ作成
        createGeometry(device: device)
        
        // 7. ユニフォームバッファ作成
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.size, options: .storageModeShared)
        
        // 8. 描画デリゲート設定
        renderDelegate = MetalRenderDelegate(view: self)
        metalView.delegate = renderDelegate
    }
    
    /// 描画パイプラインをセットアップ
    private func setupPipelines(device: MTLDevice) {
        // シェーダーライブラリを取得
        guard let library = device.makeDefaultLibrary() else {
            print("シェーダーライブラリを作成できませんでした")
            return
        }
        
        // 球体用パイプライン
        if let vertexFunc = library.makeFunction(name: "vertexShader"),
           let fragmentFunc = library.makeFunction(name: "fragmentShader") {
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunc
            pipelineDescriptor.fragmentFunction = fragmentFunc
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            
            // 半透明ブレンディング設定
            pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
            pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
            pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            
            spherePipeline = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        // ライン用パイプライン
        if let vertexFunc = library.makeFunction(name: "lineVertexShader"),
           let fragmentFunc = library.makeFunction(name: "lineFragmentShader") {
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunc
            pipelineDescriptor.fragmentFunction = fragmentFunc
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
            
            linePipeline = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
    }
    
    /// 深度ステート設定
    private func setupDepthState(device: MTLDevice) {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthDescriptor)
    }
    
    // MARK: - ジオメトリ作成
    
    /// 球体とその他のジオメトリを作成
    private func createGeometry(device: MTLDevice) {
        createSphereGeometry(device: device)
        createAxisGeometry(device: device)
        createStateVectorGeometry(device: device)
    }
    
    /// 球体ジオメトリを作成（UV球）
    private func createSphereGeometry(device: MTLDevice) {
        var vertices: [Vertex] = []
        
        let segments = 32
        let rings = 24
        let radius: Float = 0.95
        
        for ring in 0..<rings {
            for segment in 0..<segments {
                // 現在の点
                let theta1 = Float(ring) * Float.pi / Float(rings)
                let theta2 = Float(ring + 1) * Float.pi / Float(rings)
                let phi1 = Float(segment) * 2 * Float.pi / Float(segments)
                let phi2 = Float(segment + 1) * 2 * Float.pi / Float(segments)
                
                // 4つの頂点を計算
                let p1 = spherePoint(theta: theta1, phi: phi1, radius: radius)
                let p2 = spherePoint(theta: theta2, phi: phi1, radius: radius)
                let p3 = spherePoint(theta: theta2, phi: phi2, radius: radius)
                let p4 = spherePoint(theta: theta1, phi: phi2, radius: radius)
                
                // 球体の色（半透明の青）
                let color = simd_float4(0.3, 0.4, 0.8, 0.4)
                
                // 2つの三角形で四角形を構成
                vertices.append(Vertex(position: p1, normal: normalize(p1), color: color))
                vertices.append(Vertex(position: p2, normal: normalize(p2), color: color))
                vertices.append(Vertex(position: p3, normal: normalize(p3), color: color))
                
                vertices.append(Vertex(position: p1, normal: normalize(p1), color: color))
                vertices.append(Vertex(position: p3, normal: normalize(p3), color: color))
                vertices.append(Vertex(position: p4, normal: normalize(p4), color: color))
            }
        }
        
        sphereVertexCount = vertices.count
        sphereVertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: .storageModeShared)
    }
    
    /// 球面上の点を計算
    private func spherePoint(theta: Float, phi: Float, radius: Float) -> simd_float3 {
        simd_float3(
            radius * sin(theta) * cos(phi),
            radius * sin(theta) * sin(phi),
            radius * cos(theta)
        )
    }
    
    /// 軸ジオメトリを作成
    private func createAxisGeometry(device: MTLDevice) {
        var vertices: [Vertex] = []
        let axisLength: Float = 1.2
        
        // X軸（赤）
        let xColor = simd_float4(1, 0.4, 0.4, 1)
        vertices.append(Vertex(position: simd_float3(-axisLength, 0, 0), normal: simd_float3(1, 0, 0), color: xColor))
        vertices.append(Vertex(position: simd_float3(axisLength, 0, 0), normal: simd_float3(1, 0, 0), color: xColor))
        
        // Y軸（緑）
        let yColor = simd_float4(0.4, 1, 0.4, 1)
        vertices.append(Vertex(position: simd_float3(0, -axisLength, 0), normal: simd_float3(0, 1, 0), color: yColor))
        vertices.append(Vertex(position: simd_float3(0, axisLength, 0), normal: simd_float3(0, 1, 0), color: yColor))
        
        // Z軸（青）
        let zColor = simd_float4(0.4, 0.6, 1, 1)
        vertices.append(Vertex(position: simd_float3(0, 0, -axisLength), normal: simd_float3(0, 0, 1), color: zColor))
        vertices.append(Vertex(position: simd_float3(0, 0, axisLength), normal: simd_float3(0, 0, 1), color: zColor))
        
        axisVertexCount = vertices.count
        axisVertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: .storageModeShared)
    }
    
    /// 状態ベクトルジオメトリを作成
    private func createStateVectorGeometry(device: MTLDevice) {
        // 初期状態は |0⟩（北極）
        updateStateVectorBuffer(vector: .zero)
    }
    
    /// 状態ベクトルバッファを更新
    private func updateStateVectorBuffer(vector: BlochVector) {
        guard let device = device else { return }
        
        var vertices: [Vertex] = []
        let vectorColor = simd_float4(0, 1, 1, 1)  // シアン
        
        // 原点から状態ベクトルへの線
        let target = vector.float3
        vertices.append(Vertex(position: simd_float3(0, 0, 0), normal: target, color: vectorColor))
        vertices.append(Vertex(position: target, normal: target, color: vectorColor))
        
        stateVectorVertexCount = vertices.count
        stateVectorBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: .storageModeShared)
    }
    
    // MARK: - 公開メソッド
    
    /// ブロッホベクトルを設定
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
    
    /// 1フレーム描画
    func draw(in view: MTKView) {
        // アニメーション更新
        if let target = targetBlochVector, animationProgress < 1.0 {
            animationProgress += 0.08
            if animationProgress >= 1.0 {
                animationProgress = 1.0
                currentBlochVector = target
                targetBlochVector = nil
            } else {
                // 線形補間（簡易版）
                let t = animationProgress
                let currentV = currentBlochVector.vector * Double(1 - t)
                let targetV = target.vector * Double(t)
                currentBlochVector = BlochVector(currentV + targetV)
            }
            updateStateVectorBuffer(vector: currentBlochVector)
        }
        
        // 描画準備
        guard let commandBuffer = commandQueue?.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let drawable = view.currentDrawable else { return }
        
        // ユニフォーム更新
        updateUniforms(viewSize: view.drawableSize)
        
        // 深度テスト設定
        encoder.setDepthStencilState(depthState)
        
        // ユニフォームをセット
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 0)
        
        // 球体を描画
        if let pipeline = spherePipeline, let buffer = sphereVertexBuffer {
            encoder.setRenderPipelineState(pipeline)
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: sphereVertexCount)
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
    
    /// ユニフォームを更新
    private func updateUniforms(viewSize: CGSize) {
        // モデル行列（単位行列）
        let modelMatrix = matrix_identity_float4x4
        
        // ビュー行列（カメラ）
        let cameraDistance: Float = 3.5
        let cameraX = cameraDistance * cos(cameraPitch) * sin(cameraYaw)
        let cameraY = cameraDistance * sin(cameraPitch)
        let cameraZ = cameraDistance * cos(cameraPitch) * cos(cameraYaw)
        let cameraPosition = simd_float3(cameraX, cameraY, cameraZ)
        let viewMatrix = lookAt(eye: cameraPosition, center: simd_float3(0, 0, 0), up: simd_float3(0, 1, 0))
        
        // 投影行列
        let aspect = Float(viewSize.width / viewSize.height)
        let projectionMatrix = perspective(fovyRadians: Float.pi / 4, aspect: aspect, nearZ: 0.1, farZ: 100)
        
        // 法線変換行列
        let normalMatrix = simd_float3x3(
            simd_float3(modelMatrix.columns.0.x, modelMatrix.columns.0.y, modelMatrix.columns.0.z),
            simd_float3(modelMatrix.columns.1.x, modelMatrix.columns.1.y, modelMatrix.columns.1.z),
            simd_float3(modelMatrix.columns.2.x, modelMatrix.columns.2.y, modelMatrix.columns.2.z)
        )
        
        var uniforms = Uniforms(
            modelMatrix: modelMatrix,
            viewMatrix: viewMatrix,
            projectionMatrix: projectionMatrix,
            normalMatrix: normalMatrix,
            lightDirection: normalize(simd_float3(1, 1, 1)),
            cameraPosition: cameraPosition
        )
        
        uniformBuffer?.contents().copyMemory(from: &uniforms, byteCount: MemoryLayout<Uniforms>.size)
    }
    
    // MARK: - 行列計算ヘルパー
    
    /// ビュー行列を作成（lookAt）
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
    
    /// 透視投影行列を作成
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

/// MTKViewのデリゲート
/// nonisolated にすることでMTKViewDelegateの要件を満たす
private final class MetalRenderDelegate: NSObject, MTKViewDelegate {
    private weak var view: MetalBlochSphereView?
    
    init(view: MetalBlochSphereView) {
        self.view = view
        super.init()
    }
    
    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // サイズ変更時の処理（必要に応じて）
    }
    
    nonisolated func draw(in mtkView: MTKView) {
        // MainActorで描画を実行
        // selfをキャプチャせずにローカル変数を使用してデータ競合を回避
        let blochView = self.view
        Task { @MainActor in
            blochView?.draw(in: mtkView)
        }
    }
}
