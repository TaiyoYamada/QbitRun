import SwiftUI

struct GlitchQbitText: View {
    @State private var dragState = TextDragState()
    @State private var qScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 0) {
            GlitchCharacterText(character: "Q")
                .scaleEffect(qScale)
                .offset(dragState.headOffset)
                .zIndex(4)
                .gesture(
                    DragGesture()
                        .onChanged { dragState.onDragChanged($0) }
                        .onEnded { dragState.onDragEnded($0) }
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
        .task {
            await pulseLoop()
        }
    }

    private func pulseLoop() async {
        while true {
            try? await Task.sleep(for: .seconds(2.5))

            await MainActor.run {
                withAnimation(.linear(duration: 0.02)) {
                    qScale = 1.02
                }
            }

            try? await Task.sleep(nanoseconds: 50_000_000)

            await MainActor.run {
                withAnimation(.interpolatingSpring(stiffness: 180, damping: 12)) {
                    qScale = 1.0
                }
            }
        }
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
            let delay = Double.random(in: 2...4)
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
