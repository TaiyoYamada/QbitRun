import SwiftUI
import UIKit

// MARK: - Models

enum LabMode: String, CaseIterable {
    case theory = "THEORY"
    case lab = "LAB"
}

struct LabContent: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String // SF Symbols name
    let description: String
    /// Theoryモード用の画像名（Assets内の名前）
    let imageName: String?
    /// 選択時に自動再生されるアニメーションの初期ベクトル
    let initialVector: BlochVector
    /// 選択時に自動再生されるアニメーションのターゲットベクトル
    let targetVector: BlochVector?
    /// 特殊エフェクトの種類
    let effectType: EffectType
    
    enum EffectType {
        case none
        case superpositionShake
        case measurementCollapse
    }
}

// MARK: - Main View

struct HelpView: View {
    let onBack: () -> Void
    
    // MARK: - State
    @State private var currentMode: LabMode = .theory
    // 選択中のインデックス（CoverFlow用）
    @State private var centeredIndex: Int = 0
    
    // Simulation state
    @State private var blochVector: BlochVector = .zero
    @State private var showFlash: Bool = false
    
    // Data Sources
    private let theoryContents: [LabContent] = [
        LabContent(
            title: "Qubit",
            icon: "circle.circle",
            description: "A Quantum Bit (Qubit) exists in a complex vector space. It is not just 0 or 1, but a point on the Bloch Sphere.",
            imageName: "qubit_concept",
            initialVector: .zero,
            targetVector: BlochVector(x: 1, y: 0, z: 0),
            effectType: .none
        ),
        LabContent(
            title: "Superposition",
            icon: "aqi.medium",
            description: "A probability wave where both |0⟩ and |1⟩ coexist. This is the source of quantum parallelism.",
            imageName: "superposition_concept",
            initialVector: .plus,
            targetVector: nil,
            effectType: .superpositionShake
        ),
        LabContent(
            title: "Measurement",
            icon: "eye.fill",
            description: "The act of observing collapses the wave function. The universe decides on a single reality.",
            imageName: "measurement_concept",
            initialVector: .plus,
            targetVector: nil,
            effectType: .measurementCollapse
        )
    ]
    
    private let gateContents: [LabContent] = [
        LabContent(
            title: "X Gate",
            icon: "x.square",
            description: "The 'Bit Flip'. Rotates the state by π around the X-axis. Analogous to NOT gate.",
            imageName: nil,
            initialVector: .zero,
            targetVector: BlochVector(x: 0, y: 0, z: -1),
            effectType: .none
        ),
        LabContent(
            title: "H Gate",
            icon: "h.square",
            description: "The 'Hadamard'. Creates superposition from basis states. Essential for quantum interference.",
            imageName: nil,
            initialVector: .zero,
            targetVector: .plus,
            effectType: .none
        ),
        LabContent(
            title: "Z Gate",
            icon: "z.square",
            description: "The 'Phase Flip'. Rotates π around Z-axis. Modifies quantum phase without changing probability.",
            imageName: nil,
            initialVector: .plus,
            targetVector: BlochVector(x: -1, y: 0, z: 0),
            effectType: .none
        ),
        LabContent(
            title: "Y Gate",
            icon: "y.square",
            description: "Combines bit and phase flips. Rotation around Y-axis by π.",
            imageName: nil,
            initialVector: .zero,
            targetVector: BlochVector(x: 0, y: 0, z: -1),
            effectType: .none
        )
    ]
    
    var currentContents: [LabContent] {
        currentMode == .theory ? theoryContents : gateContents
    }
    
    var selectedContent: LabContent {
        // 安全にインデックスアクセス
        let index = max(0, min(centeredIndex, currentContents.count - 1))
        return currentContents[index]
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 1. Deep Space Background
            StandardBackgroundView(showGrid: true, circuitOpacity: 0.2)
            
            // Starfield (Keeping as layer 2)
            RandomStarField() 
            
            VStack(spacing: 0) {
                // 2. Holographic Display Area (Top Half)
                ZStack {
                    // Grid Floor (Perspective) - REMOVED for cleaner look

                    
                    // Main Visual (Image or Bloch Sphere)
                    mainVisualArea
                        .frame(height: 350)
                        // Add floating effect
                        .offset(y: sin(Date().timeIntervalSince1970) * 5)
                        .padding(.top, 40)
                    
                    // Mode Switcher (Top Overlay)
                    VStack {
                        navigationHeader
                        modeSwitcher
                            .padding(.top, 10)
                        Spacer()
                    }
                }
                .frame(maxHeight: .infinity)
                .zIndex(0)
                
                // 3. 3D CoverFlow Carousel (Bottom Half)
                ZStack(alignment: .bottom) {
                    // Content Info (Hologram Text above Carousel)
                    VStack(spacing: 8) {
                        Text(selectedContent.title.uppercased())
                            .font(.custom("Optima-Bold", size: 32))
                            .foregroundStyle(.white)
                            .shadow(color: .cyan, radius: 10)
                        
                        Text(selectedContent.description)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .lineLimit(3)
                    }
                    .padding(.bottom, 180) // Lift above carousel
                    .transition(.opacity.combined(with: .scale))
                    .id(selectedContent.id) // Animate text change
                    
                    // The Carousel itself
                    CoverFlowCarousel(
                        items: currentContents,
                        centeredIndex: $centeredIndex
                    )
                    .frame(height: 160)
                    .padding(.bottom, 20)
                }
                .frame(height: 300)
                .zIndex(1) // Above floor
            }
        }
        .onChange(of: centeredIndex) { oldValue, newValue in
            triggerHaptic()
            playSimulation()
        }
        .onChange(of: currentMode) {oldValue, newValue in
            centeredIndex = 0
            playSimulation()
        }
        .onAppear {
            playSimulation()
        }
    }
    
    // MARK: - Components
    
    private var mainVisualArea: some View {
        ZStack {
            if currentMode == .theory, let imageName = selectedContent.imageName {
                // SF Concept Image
                Image(imageName) // Asset catalog based
                    .resizable()
                    .scaledToFit()
                    .mask(
                        LinearGradient(
                            colors: [.black, .black, .black, .clear],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 20)
                    .id(imageName)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            } else {
                // Interactive Bloch Sphere
                BlochSphereViewRepresentable(
                    vector: blochVector,
                    animated: true,
                    showBackground: false,
                    showAxes: true,
                    showAxisLabels: true,
                    continuousOrbitAnimation: false
                )
                .scaleEffect(0.9)
                .id("BlochSphere")
            }
            
            // Measurement Flash
            if showFlash {
                Color.white
                    .blendMode(.screen)
                    .ignoresSafeArea()
                    .opacity(showFlash ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: showFlash)
            }
        }
    }
    
    private var navigationHeader: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            // Title is now implied by context
        }
        .padding(.horizontal, 24)
    }
    
    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(LabMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring()) {
                        currentMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.custom("Optima-Bold", size: 14))
                        .foregroundStyle(currentMode == mode ? .black : .white)
                        .frame(width: 100, height: 32)
                        .background(
                            currentMode == mode ? Color.cyan : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
    }
    
    // MARK: - Logic (Same as before)
    
    private func playSimulation() {
        let content = selectedContent
        
        showFlash = false
        blochVector = content.initialVector
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch content.effectType {
            case .none:
                if let target = content.targetVector {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self.blochVector = target
                    }
                }
            case .superpositionShake:
                animateSuperposition()
            case .measurementCollapse:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    performMeasurement()
                }
            }
        }
    }
    
    private func animateSuperposition() {
        guard selectedContent.effectType == .superpositionShake else { return }
        
        Task { @MainActor in
            let angles = [0.0, 90.0, 180.0, 270.0]
            var i = 0
            
            while selectedContent.effectType == .superpositionShake {
                let angle = angles[i % 4]
                let rad = angle * .pi / 180
                let x = cos(rad)
                let y = sin(rad)
                
                withAnimation(.linear(duration: 0.5)) {
                    self.blochVector = BlochVector(x: x, y: y, z: 0)
                }
                
                i += 1
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            }
        }
    }
    
    private func performMeasurement() {
        guard selectedContent.effectType == .measurementCollapse else { return }
        showFlash = true
        let result = Bool.random() ? BlochVector.zero : BlochVector(x: 0, y: 0, z: -1)
        self.blochVector = result
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
             showFlash = false // Fade out handled by animation value
        }
        
        // Retry loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.selectedContent.effectType == .measurementCollapse {
                self.blochVector = .plus
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.performMeasurement()
                }
            }
        }
    }
    
    private func triggerHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - 3D CoverFlow Components

struct CoverFlowCarousel: View {
    let items: [LabContent]
    @Binding var centeredIndex: Int
    @State private var scrolledID: Int?
    
    var body: some View {
        GeometryReader { fullGeo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<items.count, id: \.self) { index in
                        GeometryReader { geo in
                            let midX = geo.frame(in: .global).midX
                            let screenMidX = fullGeo.frame(in: .global).midX
                            let dist = midX - screenMidX
                            
                            // 3D Transforms
                            let rotation = Double(dist / -10)
                            let scale = 1.0 - abs(dist / fullGeo.size.width) * 0.3
                            
                            CoverFlowCard(content: items[index])
                                .rotation3DEffect(
                                    .degrees(rotation),
                                    axis: (x: 0, y: 1, z: 0),
                                    perspective: 0.5
                                )
                                .scaleEffect(scale)
                                .opacity(1.0 - abs(dist / fullGeo.size.width) * 0.5)
                                .onTapGesture {
                                    withAnimation {
                                        scrolledID = index
                                    }
                                }
                        }
                        .frame(width: 160, height: 160)
                        .id(index) // Essential for scrollPosition
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $scrolledID)
            .contentMargins(.horizontal, (fullGeo.size.width - 160) / 2, for: .scrollContent)
            .onAppear {
                if scrolledID == nil {
                    scrolledID = centeredIndex
                }
            }
            .onChange(of: scrolledID) { _, newValue in
                if let val = newValue {
                    centeredIndex = val
                }
            }
            .onChange(of: centeredIndex) { _, newValue in
                if scrolledID != newValue {
                    withAnimation {
                        scrolledID = newValue
                    }
                }
            }
        }
    }
}

struct CoverFlowCard: View {
    let content: LabContent
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .cyan.opacity(0.4), radius: 10)
            
            VStack {
                Image(systemName: content.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .shadow(color: .white, radius: 5)
                
                Text(content.title)
                    .font(.custom("Optima-Bold", size: 16))
                    .foregroundStyle(.cyan)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Visual Effects

struct RandomStarField: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<50) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: 2, height: 2)
                    .position(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height)
                    )
                    .opacity(Double.random(in: 0.1...0.8))
            }
        }
        .allowsHitTesting(false)
    }
}

struct PerspectiveGrid: View {
    var body: some View {
        // Simple converging lines using path
        Canvas { context, size in
            var path = Path()
            let horizonY = 0.0
            let bottomY = size.height
            let centerX = size.width / 2
            
            // Vertical lines converging to vanishing point
            for i in -5...5 {
                path.move(to: CGPoint(x: centerX, y: horizonY)) // Vanishing point
                path.addLine(to: CGPoint(x: centerX + CGFloat(i) * 200, y: bottomY))
            }
            
            // Horizontal lines
            for i in 1...10 {
                let y = bottomY * (Double(i) / 10.0)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            
            context.stroke(
                path,
                with: .color(.cyan.opacity(0.3)),
                lineWidth: 1
            )
        }
        .mask(
            LinearGradient(colors: [.black, .white], startPoint: .top, endPoint: .bottom)
        )
    }
}
//
//#Preview("Quantum Lab 2.0") {
//    HelpView(onBack: {})
//        .preferredColorScheme(.dark)
//}
