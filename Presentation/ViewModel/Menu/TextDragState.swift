import SwiftUI

@Observable
@MainActor
final class TextDragState {
    var headOffset: CGSize = .zero
    var followerOffsets: [CGSize] = [.zero, .zero, .zero]

    @ObservationIgnored
    private var history: [(time: Double, offset: CGSize)] = []

    @ObservationIgnored
    private var isDragging = false

    @ObservationIgnored
    private var baseTime: Double = 0.0

    @ObservationIgnored
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
        guard let last = history.last else { return .zero }

        if targetTime >= last.time {
            return last.offset
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

        return history.first?.offset ?? .zero
    }
}
