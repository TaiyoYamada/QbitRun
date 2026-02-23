import SwiftUI

@MainActor
class TextDragState: ObservableObject {
    @Published var headOffset: CGSize = .zero
    @Published var followerOffsets: [CGSize] = [.zero, .zero, .zero]
    
    private var history: [(time: Double, offset: CGSize)] = []
    private var isDragging = false
    private var baseTime: Double = 0.0
    private var updateTask: Task<Void, Never>?
    
    func onDragChanged(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            history.removeAll()
            baseTime = Date().timeIntervalSince1970
            history.append((0.0, .zero))
            startTask()
        }
        headOffset = value.translation
        let t = Date().timeIntervalSince1970 - baseTime
        history.append((t, value.translation))
        
        let oldestNeededTime = t - 1.0
        while history.count > 10, let first = history.first, first.time < oldestNeededTime {
            history.removeFirst()
        }
    }
    
    func onDragEnded(_ value: DragGesture.Value) {
        isDragging = false
        updateTask?.cancel()
        updateTask = nil
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            headOffset = .zero
            for i in 0..<3 {
                followerOffsets[i] = .zero
            }
        }
    }
    
    private func startTask() {
        guard updateTask == nil else { return }
        updateTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.updateFollowers()
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }
    
    private func updateFollowers() {
        let delays: [Double] = [0.08, 0.16, 0.24]
        let currentTime = Date().timeIntervalSince1970 - baseTime
        
        for i in 0..<3 {
            let targetTime = currentTime - delays[i]
            if targetTime <= 0 {
                followerOffsets[i] = .zero
            } else {
                followerOffsets[i] = interpolate(at: targetTime)
            }
        }
    }
    
    private func interpolate(at targetTime: Double) -> CGSize {
        guard history.count > 1 else { return history.last?.offset ?? .zero }
        if targetTime >= history.last!.time {
            return history.last!.offset
        }
        
        for i in (0..<history.count-1).reversed() {
            let p1 = history[i]
            let p2 = history[i+1]
            if targetTime >= p1.time && targetTime <= p2.time {
                let dt = p2.time - p1.time
                if dt == 0 { return p1.offset }
                let fraction = CGFloat((targetTime - p1.time) / dt)
                let dx = p1.offset.width + (p2.offset.width - p1.offset.width) * fraction
                let dy = p1.offset.height + (p2.offset.height - p1.offset.height) * fraction
                return CGSize(width: dx, height: dy)
            }
        }
        return history.first!.offset
    }
}

struct GlitchQbitText: View {
    @StateObject private var dragState = TextDragState()

    var body: some View {
        HStack(spacing: 0) {
            GlitchCharacterText(character: "Q")
                .offset(dragState.headOffset)
                .zIndex(4)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragState.onDragChanged(value)
                        }
                        .onEnded { value in
                            dragState.onDragEnded(value)
                        }
                )
            
            GlitchCharacterText(character: "b")
                .offset(dragState.followerOffsets[0])
                .zIndex(3)
            
            GlitchCharacterText(character: "i")
                .offset(dragState.followerOffsets[1])
                .zIndex(2)
            
            GlitchCharacterText(character: "t")
                .offset(dragState.followerOffsets[2])
                .zIndex(1)
        }
        .shadow(color: .cyan.opacity(0.5), radius: 5)
    }
}

struct GlitchCharacterText: View {
    let character: String
    let sliceCount = 15

    @State private var offsets: [CGFloat] = Array(repeating: 0, count: 15)

    var body: some View {
        ZStack {
            ForEach(0..<sliceCount, id: \.self) { index in
                baseText
                    .mask(
                        GeometryReader { proxy in
                            let sliceHeight = proxy.size.height / CGFloat(sliceCount)
                            Rectangle()
                                .frame(width: proxy.size.width, height: sliceHeight)
                                .offset(y: sliceHeight * CGFloat(index))
                        }
                    )
                    .offset(x: offsets[index])
            }
        }
        .drawingGroup(opaque: false)
        .task {
            await glitchLoop()
        }
    }

    private var baseText: some View {
        ZStack {
            Text(character)
                .font(.system(size: 205, weight: .bold, design: .rounded))
                .tracking(13)
                .foregroundStyle(.white.opacity(0.8))

            Text(character)
                .font(.system(size: 195, weight: .bold, design: .rounded))
                .tracking(13)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.98, blue: 1.0),
                            Color(red: 0.24, green: 0.36, blue: 0.82),
                            Color(red: 0.25, green: 0.08, blue: 0.48)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    @MainActor
    private func glitchLoop() async {
        while !Task.isCancelled {
            let delay = Double.random(in: 1...4)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))


            if Task.isCancelled { break }

            let catastrophic = Int.random(in: 0...12) == 0

            let glitchCount = catastrophic
                ? Int.random(in: 10...sliceCount)
                : Int.random(in: 5...10)

            let active = offsets.indices.shuffled().prefix(glitchCount)

            withAnimation(.linear(duration: 0.05)) {
                for i in active {
                    offsets[i] = randomGaussian() * (catastrophic ? 20 : 5)
                }
            }

            try? await Task.sleep(nanoseconds: 60_000_000)

            withAnimation(.easeOut(duration: catastrophic ? 0.20 : 0.15)) {
                for i in active {
                    offsets[i] = 0
                }
            }
        }
    }

    private func randomGaussian() -> CGFloat {
        let u1 = Double.random(in: 0...1)
        let u2 = Double.random(in: 0...1)
        let z = sqrt(-2 * log(u1)) * cos(2 * .pi * u2)
        return CGFloat(z)
    }
}
