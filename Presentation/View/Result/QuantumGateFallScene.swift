import SpriteKit
import SwiftUI

class QuantumGateFallScene: SKScene {
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        setupPhysicsBoundary()
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        setupPhysicsBoundary()
    }
    
    private var textureCache: [QuantumGate: SKTexture] = [:]

    private func setupPhysicsBoundary() {
        let path = CGMutablePath()
        let extensionHeight: CGFloat = 1000
        
        path.move(to: CGPoint(x: 0, y: self.size.height + extensionHeight))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: self.size.width, y: 0))
        path.addLine(to: CGPoint(x: self.size.width, y: self.size.height + extensionHeight))
        
        self.physicsBody = SKPhysicsBody(edgeChainFrom: path)
        self.physicsBody?.friction = 0.5
    }
    
    func startDropping(totalBlocks: Int, duration: TimeInterval) {
        let maxBlocks = min(totalBlocks, 200)
        if maxBlocks <= 0 { return }
        
        let dropInterval = duration / Double(maxBlocks)

        let waitAction = SKAction.wait(forDuration: dropInterval)
        let dropAction = SKAction.run { [weak self] in
            self?.dropSingleGate()
        }
        
        let sequence = SKAction.sequence([dropAction, waitAction])
        let repeatAction = SKAction.repeat(sequence, count: maxBlocks)
        
        self.run(repeatAction)
    }
    
    private func getTexture(for gate: QuantumGate) -> SKTexture {
        if let tex = textureCache[gate] { return tex }
        
        let gateSize = CGSize(width: 40, height: 40)
        let cornerRadius: CGFloat = 8.0 * (40.0 / 60.0)
        
        let renderer = UIGraphicsImageRenderer(size: gateSize)
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: gateSize)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            
            gate.color.setFill()
            path.fill()
            
            let text = gate.symbol
            let font = UIFont.systemFont(ofSize: 20, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (gateSize.width - textSize.width) / 2,
                y: (gateSize.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        let texture = SKTexture(image: image)
        textureCache[gate] = texture
        return texture
    }

    private func dropSingleGate() {
        guard let gate = QuantumGate.allCases.randomElement() else { return }

        let gateSize = CGSize(width: 40, height: 40)
        let texture = getTexture(for: gate)
        let sprite = SKSpriteNode(texture: texture)
        
        sprite.position = CGPoint(
            x: CGFloat.random(in: gateSize.width...(self.size.width - gateSize.width)),
            y: self.size.height + gateSize.height
        )

        sprite.zRotation = CGFloat.random(in: 0...(2 * .pi))
        
        sprite.physicsBody = SKPhysicsBody(rectangleOf: gateSize)
        sprite.physicsBody?.restitution = 0.3
        sprite.physicsBody?.density = 1.0
        sprite.physicsBody?.allowsRotation = true
        
        sprite.alpha = 0.6
        
        self.addChild(sprite)
    }
}
