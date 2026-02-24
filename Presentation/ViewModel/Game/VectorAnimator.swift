import SwiftUI
import simd

@Observable
@MainActor
final class VectorAnimator {

    struct AnimationStep {
        let path: AnimationPath
        let duration: Double
    }

    enum AnimationPath {
        case axisRotation(start: simd_double3, axis: simd_double3, angle: Double)
        case slerp(from: simd_double3, to: simd_double3)
    }

    enum Config {
        static let fps: Double = 60
        static let addOrRemoveDuration: Double = 0.16
        static let clearDuration: Double = 0.22
        static let minimumDuration: Double = 0.016
    }

    private(set) var animatedVector: BlochVector?

    @ObservationIgnored
    private var queue: [AnimationStep] = []

    @ObservationIgnored
    private var animationTask: Task<Void, Never>?

    func enqueue(path: AnimationPath, baseDuration: Double) {
        if case let .slerp(from, to) = path {
            guard simd_distance(from, to) > 0.000_1 else { return }
        }

        let duration = adjustedDuration(for: baseDuration)
        let step = AnimationStep(path: path, duration: duration)
        queue.append(step)
        startIfNeeded()
    }

    func reset() {
        animationTask?.cancel()
        animationTask = nil
        queue.removeAll(keepingCapacity: false)
        animatedVector = nil
    }

    private func startIfNeeded() {
        guard animationTask == nil else { return }

        animationTask = Task { @MainActor in
            await self.processQueue()
        }
    }

    private func processQueue() async {
        defer {
            animationTask = nil
            animatedVector = nil
        }

        while !queue.isEmpty {
            if Task.isCancelled { break }
            let step = queue.removeFirst()
            await animateStep(step)
        }
    }

    private func animateStep(_ step: AnimationStep) async {
        let totalFrames = max(1, Int(step.duration * Config.fps))
        let frameDurationNs = UInt64(1_000_000_000 / Config.fps)

        for frame in 0...totalFrames {
            if Task.isCancelled { return }

            let progress = Double(frame) / Double(totalFrames)
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            let interpolated: simd_double3
            switch step.path {
            case let .axisRotation(start, axis, angle):
                let currentAngle = angle * easedProgress
                interpolated = rotate(vector: start, axis: axis, angle: currentAngle)
            case let .slerp(from, to):
                interpolated = slerp(from: from, to: to, t: easedProgress)
            }
            animatedVector = BlochVector(interpolated)

            if frame < totalFrames {
                do {
                    try await Task.sleep(nanoseconds: frameDurationNs)
                } catch {
                    return
                }
            }
        }
    }

    private func adjustedDuration(for baseDuration: Double) -> Double {
        let backlog = queue.count + (animationTask == nil ? 0 : 1)
        let factor: Double
        switch backlog {
        case 0...1:
            factor = 1.0
        case 2:
            factor = 0.45
        case 3:
            factor = 0.33
        case 4:
            factor = 0.25
        case 5:
            factor = 0.18
        default:
            factor = 0.12
        }

        return max(Config.minimumDuration, baseDuration * factor)
    }


    func slerp(from source: simd_double3, to destination: simd_double3, t: Double) -> simd_double3 {
        let clampedT = max(0.0, min(1.0, t))
        let from = simd_normalize(source)
        let to = simd_normalize(destination)
        let dot = max(-1.0, min(1.0, simd_dot(from, to)))

        if dot > 0.9995 {
            return simd_normalize(from * (1.0 - clampedT) + to * clampedT)
        }

        if dot < -0.9995 {
            var orthogonal = simd_cross(from, simd_double3(1, 0, 0))
            if simd_length_squared(orthogonal) < 0.000001 {
                orthogonal = simd_cross(from, simd_double3(0, 1, 0))
            }
            orthogonal = simd_normalize(orthogonal)
            let rotation = simd_quatd(angle: .pi * clampedT, axis: orthogonal)
            return simd_normalize(rotation.act(from))
        }

        let angle = acos(dot)
        let sinAngle = sin(angle)
        let fromWeight = sin((1.0 - clampedT) * angle) / sinAngle
        let toWeight = sin(clampedT * angle) / sinAngle
        return simd_normalize(from * fromWeight + to * toWeight)
    }

    func rotate(vector: simd_double3, axis: simd_double3, angle: Double) -> simd_double3 {
        let rotationWrapper = simd_quatd(angle: angle, axis: axis)
        return rotationWrapper.act(vector)
    }
}
