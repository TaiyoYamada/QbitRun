// SPDX-License-Identifier: MIT
// Rendering/BinaryRainLayer.swift
// Matrix風バイナリレイン（CAEmitterLayer版 - 高パフォーマンス）

import UIKit

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// パフォーマンス最適化（AGENTS.md準拠）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// CAEmitterLayerはGPU上で動作し、毎フレームのCPU処理が不要
// - shadowなし（重い）
// - プログラムでのopacity更新なし
// - CADisplayLinkなし（パーティクルシステムが自動管理）
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// 蛍光黄緑
private let matrixGreenColor = UIColor(red: 0.224, green: 1.0, blue: 0.078, alpha: 1.0)

/// Matrix風のバイナリレイン（CAEmitterLayer版）
@MainActor
public final class BinaryRainLayer: CALayer {
    
    // MARK: - Constants
    
    /// 列数
    private let columnCount: Int = 25
    
    /// フォントサイズ
    private let fontSize: CGFloat = 18
    
    // MARK: - Properties
    
    /// 列ごとのエミッター
    private var columnEmitters: [CAEmitterLayer] = []
    
    /// 事前レンダリング画像
    private var image0: CGImage?
    private var image1: CGImage?
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
        backgroundColor = UIColor.black.cgColor
    }
    
    public override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) は未実装です")
    }
    
    // MARK: - Public Methods
    
    /// レイン開始
    public func startRain(in size: CGSize) {
        // 既存を削除
        stopRain()
        
        // 画像をレンダリング（初回のみ）
        if image0 == nil || image1 == nil {
            renderCharacterImages()
        }
        
        guard let img0 = image0, let img1 = image1 else { return }
        
        let columnWidth = size.width / CGFloat(columnCount)
        
        // 各列に独立したエミッターを作成
        for column in 0..<columnCount {
            let emitter = CAEmitterLayer()
            
            // 列の位置（各列の中央上部）
            let xPosition = columnWidth * CGFloat(column) + columnWidth / 2
            emitter.emitterPosition = CGPoint(x: xPosition, y: -10)
            emitter.emitterSize = CGSize(width: 1, height: 1)
            emitter.emitterShape = .point
            
            // 列ごとにランダムな速度
            let speed = CGFloat.random(in: 100...180)
            
            // 文字間隔
            let characterSpacing: CGFloat = fontSize * 2.0
            
            // 0と1のセル（タイミングをずらして被らないように）
            let cell0 = createCell(image: img0, speed: speed, viewHeight: size.height, characterSpacing: characterSpacing)
            let cell1 = createCell(image: img1, speed: speed, viewHeight: size.height, characterSpacing: characterSpacing)
            
            // タイミングをずらす（文字間隔分の時間差）
            let timeOffset = Double(characterSpacing / speed)
            cell0.beginTime = 0
            cell1.beginTime = timeOffset
            
            emitter.emitterCells = [cell0, cell1]
            
            // 列ごとにランダムな開始遅延
            emitter.beginTime = CACurrentMediaTime() + Double.random(in: 0...1.0)
            
            addSublayer(emitter)
            columnEmitters.append(emitter)
        }
    }
    
    /// フェードアウト
    public func fadeOut(duration: TimeInterval = 2.0) {
        let fadeAnimation = CABasicAnimation(keyPath: "opacity")
        fadeAnimation.fromValue = 1.0
        fadeAnimation.toValue = 0.2
        fadeAnimation.duration = duration
        fadeAnimation.fillMode = .forwards
        fadeAnimation.isRemovedOnCompletion = false
        add(fadeAnimation, forKey: "fadeOut")
    }
    
    /// レイン停止
    public func stopRain() {
        columnEmitters.forEach { $0.removeFromSuperlayer() }
        columnEmitters.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func renderCharacterImages() {
        image0 = renderCharacter("0")
        image1 = renderCharacter("1")
    }
    
    private func renderCharacter(_ char: String) -> CGImage? {
        let size = CGSize(width: fontSize * 1.2, height: fontSize * 1.4)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { _ in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Menlo-Bold", size: fontSize) ?? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: matrixGreenColor
            ]
            
            let attrString = NSAttributedString(string: char, attributes: attributes)
            let textSize = attrString.size()
            let x = (size.width - textSize.width) / 2
            let y = (size.height - textSize.height) / 2
            attrString.draw(at: CGPoint(x: x, y: y))
        }
        
        return image.cgImage
    }
    
    private func createCell(image: CGImage, speed: CGFloat, viewHeight: CGFloat, characterSpacing: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = image
        
        // 発生レート（0と1で交互に出るので、各セルは半分のレート）
        cell.birthRate = Float(speed / characterSpacing) * 0.3
        
        // 寿命（画面を通過する時間 + 余裕）
        cell.lifetime = Float(viewHeight / speed) + 2
        cell.lifetimeRange = 0
        
        // 速度
        cell.velocity = speed
        cell.velocityRange = 0
        
        // 方向（真下）
        cell.emissionLongitude = .pi / 2
        cell.emissionRange = 0
        
        // 透明度（時間とともにフェード）
        cell.alphaSpeed = -0.2
        
        // スケール
        cell.scale = 1.0
        cell.scaleRange = 0
        
        return cell
    }
}
