// SPDX-License-Identifier: MIT
// Rendering/BlochSphereView.swift
// ブロッホ球ビュー（Metal利用可能時はMetal、そうでなければCore Graphics）

import UIKit
import simd

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// このクラスの役割
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ブロッホ球を描画するビュー
//
// 内部的に2つの描画方法を持つ:
// 1. Metal: GPU描画（高品質な3D、利用可能な場合）
// 2. Core Graphics: CPU描画（フォールバック）
//
// 外部からは setVector() を呼ぶだけで
// 内部で適切な描画方法が選ばれる
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// ブロッホ球を描画するビュー
/// Metal対応デバイスではMetalを使用、そうでなければCore Graphicsにフォールバック
@MainActor
public final class BlochSphereView: UIView {
    
    // MARK: - プロパティ
    
    /// 現在表示しているブロッホベクトル
    private var currentVector: BlochVector = .zero
    
    /// Metal版ビュー（利用可能な場合）
    private var metalView: MetalBlochSphereView?
    
    /// Metalを使用するかどうか
    private var useMetal: Bool = true
    
    /// アニメーション用のディスプレイリンク（Core Graphicsフォールバック時）
    private var targetVector: BlochVector?
    private var animationDisplayLink: CADisplayLink?
    private var animationStartVector: BlochVector?
    private var animationProgress: CGFloat = 1.0
    
    /// カメラ角度（Core Graphics描画時の視点）
    private var cameraAngle: CGFloat = 0.3
    
    // MARK: - 初期化
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未実装です")
    }
    
    // MARK: - ライフサイクル
    
    /// ウィンドウから削除される直前に呼ばれる
    /// ディスプレイリンクのクリーンアップを行う
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            // ウィンドウから離れる時にディスプレイリンクを停止
            animationDisplayLink?.invalidate()
            animationDisplayLink = nil
        }
    }
    
    // MARK: - セットアップ
    
    private func setupView() {
        backgroundColor = .clear
        isOpaque = false  // 透明描画を許可
        layer.cornerRadius = 8
        clipsToBounds = true
        
        // Metal対応デバイスかチェック
        if MTLCreateSystemDefaultDevice() != nil {
            setupMetalView()
        } else {
            useMetal = false
        }
    }
    
    /// Metal版ビューをセットアップ
    private func setupMetalView() {
        metalView = MetalBlochSphereView(frame: bounds)
        metalView!.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metalView!)
        
        // 親ビューいっぱいに広げる
        NSLayoutConstraint.activate([
            metalView!.topAnchor.constraint(equalTo: topAnchor),
            metalView!.bottomAnchor.constraint(equalTo: bottomAnchor),
            metalView!.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView!.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    // MARK: - 公開メソッド
    
    /// ブロッホベクトルを設定
    /// - Parameters:
    ///   - vector: 表示するブロッホベクトル
    ///   - animated: アニメーションするかどうか
    public func setVector(_ vector: BlochVector, animated: Bool = false) {
        currentVector = vector
        
        if useMetal, let metalView = metalView {
            // Metal版に任せる
            metalView.setVector(vector, animated: animated)
        } else {
            // Core Graphicsで描画
            if animated {
                animateToVector(vector)
            } else {
                setNeedsDisplay()  // 再描画をリクエスト
            }
        }
    }
    
    // MARK: - アニメーション（Core Graphicsフォールバック）
    
    /// ベクトルへアニメーション
    private func animateToVector(_ target: BlochVector) {
        animationDisplayLink?.invalidate()
        
        targetVector = target
        animationStartVector = currentVector
        animationProgress = 0
        
        // CADisplayLink: 画面リフレッシュに同期してコールバック
        // SwiftUIの TimelineView に相当
        animationDisplayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        animationDisplayLink?.add(to: .main, forMode: .common)
    }
    
    /// アニメーションフレーム更新
    @objc private func updateAnimation() {
        animationProgress += 0.08  // 約12フレームで完了
        
        if animationProgress >= 1.0 {
            animationProgress = 1.0
            animationDisplayLink?.invalidate()
            animationDisplayLink = nil
            
            if let target = targetVector {
                currentVector = target
            }
        } else if let start = animationStartVector, let end = targetVector {
            // 球面線形補間（Slerp）
            currentVector = slerp(from: start, to: end, t: Double(animationProgress))
        }
        
        setNeedsDisplay()
    }
    
    /// 球面線形補間（Spherical Linear Interpolation）
    /// 3D空間で2点間を「球面上を通って」補間する
    private func slerp(from: BlochVector, to: BlochVector, t: Double) -> BlochVector {
        let dot = simd_dot(from.vector, to.vector)
        let theta = acos(max(-1, min(1, dot)))
        
        if theta < 0.001 {
            // ほぼ同じ方向なら線形補間
            let interpolated = from.vector * (1 - t) + to.vector * t
            return BlochVector(interpolated)
        }
        
        let sinTheta = sin(theta)
        let a = sin((1 - t) * theta) / sinTheta
        let b = sin(t * theta) / sinTheta
        
        let result = from.vector * a + to.vector * b
        return BlochVector(result)
    }
    
    // MARK: - Core Graphics描画（フォールバック）
    
    /// カスタム描画
    public override func draw(_ rect: CGRect) {
        // Metalを使用している場合は何もしない
        guard !useMetal else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.4
        
        drawSphereBackground(in: context, center: center, radius: radius)
        drawAxes(in: context, center: center, radius: radius)
        drawStateVector(in: context, center: center, radius: radius)
        drawSphereOutline(in: context, center: center, radius: radius)
    }
    
    /// 球の背景（グラデーション）を描画
    private func drawSphereBackground(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let colors = [
            UIColor(white: 0.2, alpha: 0.4).cgColor,
            UIColor(white: 0.1, alpha: 0.6).cgColor
        ]
        
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0, 1]) {
            context.saveGState()
            context.addEllipse(in: CGRect(x: center.x - radius,
                                          y: center.y - radius,
                                          width: radius * 2,
                                          height: radius * 2))
            context.clip()
            context.drawRadialGradient(gradient,
                                       startCenter: CGPoint(x: center.x - radius * 0.3,
                                                           y: center.y - radius * 0.3),
                                       startRadius: 0,
                                       endCenter: center,
                                       endRadius: radius * 1.2,
                                       options: [])
            context.restoreGState()
        }
    }
    
    /// 軸を描画
    private func drawAxes(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let axisLength = radius * 0.85
        
        let xColor = UIColor(red: 1, green: 0.4, blue: 0.4, alpha: 0.7)
        let yColor = UIColor(red: 0.4, green: 1, blue: 0.4, alpha: 0.7)
        let zColor = UIColor(red: 0.4, green: 0.6, blue: 1, alpha: 0.8)
        
        // X軸
        let xEnd = project3DPoint(simd_double3(1, 0, 0), center: center, radius: axisLength)
        drawAxis(in: context, from: center, to: xEnd, color: xColor, label: "X")
        
        // Y軸
        let yEnd = project3DPoint(simd_double3(0, 1, 0), center: center, radius: axisLength)
        drawAxis(in: context, from: center, to: yEnd, color: yColor, label: "Y")
        
        // Z軸
        let zEnd = project3DPoint(simd_double3(0, 0, 1), center: center, radius: axisLength)
        drawAxis(in: context, from: center, to: zEnd, color: zColor, label: "Z")
        
        // 基底状態ラベル
        drawBasisLabel("|0⟩", at: project3DPoint(simd_double3(0, 0, 1.15), center: center, radius: axisLength), in: context)
        drawBasisLabel("|1⟩", at: project3DPoint(simd_double3(0, 0, -1.15), center: center, radius: axisLength), in: context)
    }
    
    /// 1本の軸を描画
    private func drawAxis(in context: CGContext, from: CGPoint, to: CGPoint, color: UIColor, label: String) {
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1.5)
        context.setLineCap(.round)
        
        context.move(to: from)
        context.addLine(to: to)
        context.strokePath()
        
        context.restoreGState()
    }
    
    /// 基底状態ラベルを描画
    private func drawBasisLabel(_ text: String, at point: CGPoint, in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        
        let string = NSAttributedString(string: text, attributes: attributes)
        let size = string.size()
        let rect = CGRect(x: point.x - size.width / 2,
                         y: point.y - size.height / 2,
                         width: size.width,
                         height: size.height)
        
        UIGraphicsPushContext(context)
        string.draw(in: rect)
        UIGraphicsPopContext()
    }
    
    /// 状態ベクトルを描画
    private func drawStateVector(in context: CGContext, center: CGPoint, radius: CGFloat) {
        let vectorEnd = project3DPoint(currentVector.vector, center: center, radius: radius * 0.9)
        
        // ベクトル線（グロー付き）
        context.saveGState()
        context.setShadow(offset: .zero, blur: 8, color: UIColor.cyan.withAlphaComponent(0.6).cgColor)
        context.setStrokeColor(UIColor.cyan.cgColor)
        context.setLineWidth(3)
        context.setLineCap(.round)
        
        context.move(to: center)
        context.addLine(to: vectorEnd)
        context.strokePath()
        context.restoreGState()
        
        // 先端の点
        context.saveGState()
        context.setShadow(offset: .zero, blur: 10, color: UIColor.white.withAlphaComponent(0.8).cgColor)
        context.setFillColor(UIColor.white.cgColor)
        context.addArc(center: vectorEnd, radius: 6, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.fillPath()
        context.restoreGState()
    }
    
    /// 球の輪郭を描画
    private func drawSphereOutline(in context: CGContext, center: CGPoint, radius: CGFloat) {
        context.saveGState()
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        
        // 外周円
        context.addEllipse(in: CGRect(x: center.x - radius,
                                       y: center.y - radius,
                                       width: radius * 2,
                                       height: radius * 2))
        context.strokePath()
        
        // 赤道（楕円で擬似3D効果）
        let equatorRect = CGRect(x: center.x - radius,
                                  y: center.y - radius * 0.3,
                                  width: radius * 2,
                                  height: radius * 0.6)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.15).cgColor)
        context.addEllipse(in: equatorRect)
        context.strokePath()
        
        context.restoreGState()
    }
    
    /// 3D点を2D画面座標に投影
    private func project3DPoint(_ point: simd_double3, center: CGPoint, radius: CGFloat) -> CGPoint {
        let rotationY = Double(cameraAngle)
        let cosY = cos(rotationY)
        let sinY = sin(rotationY)
        
        // Y軸周りに回転
        let rotatedX = point.x * cosY - point.y * sinY
        let rotatedZ = point.z
        
        // 2D投影（簡易的な等角投影）
        let screenX = center.x + CGFloat(rotatedX) * radius
        let screenY = center.y - CGFloat(rotatedZ) * radius
        
        return CGPoint(x: screenX, y: screenY)
    }
}
