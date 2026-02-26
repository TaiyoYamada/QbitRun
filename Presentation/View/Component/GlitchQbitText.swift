import SwiftUI

struct GlitchQbitText: View {
    @State private var dragState = TextDragState()

    var body: some View {
        HStack(spacing: 0) {
            GlitchCharacterText(character: "O")
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
            if character == "O" {
                arrowOverlay
            }
        }
    }

    @MainActor
    private func glitchLoop() async {
        while !Task.isCancelled {
            let delay = Double.random(in: 2...5)
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

    private var arrowOverlay: some View {

        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.60, blue: 0.60),
                Color(red: 0.85, green: 0.00, blue: 0.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(width: 150, height: 200)
        .mask(
            ZStack {
                Capsule()
                    .frame(width: 95, height: 30)
                    .rotationEffect(.degrees(50))
                    .offset(x: 30, y: 45)

                Triangle()
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(140))
                    .offset(x: 60, y: 82)
            }
        )
        .overlay(
            Color.black.opacity(0.35)
                .mask(
                    ZStack {
                        Capsule()
                            .frame(width: 150, height: 30)
                            .rotationEffect(.degrees(50))
                            .offset(x: 30, y: 45)

                        Triangle()
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(140))
                            .offset(x: 60, y: 82)
                    }
                )
                .blur(radius: 8)
                .offset(x: -1, y: 25)
                .mask(
                    ZStack {
                        Capsule()
                            .frame(width: 95, height: 30)
                            .rotationEffect(.degrees(50))
                            .offset(x: 30, y: 45)

                        Triangle()
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(140))
                            .offset(x: 60, y: 82)
                    }
                )
                .blendMode(.multiply)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 3)
    }
}


fileprivate struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX,
                              y: rect.minY + 10))

        path.addLine(to: CGPoint(x: rect.maxX - 4,
                                 y: rect.maxY))

        path.addLine(to: CGPoint(x: rect.minX + 4,
                                 y: rect.maxY))

        path.closeSubpath()
        return path
    }
}
