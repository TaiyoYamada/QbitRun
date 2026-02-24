import SwiftUI
import simd

@Observable
@MainActor
final class TutorialManager {

    private(set) var currentStep: TutorialStep = .intro1
    private(set) var isActive: Bool = false
    private(set) var showNextButton: Bool = true
    private(set) var gateEnabled: Bool = false

    private var furthestReachedIndex: Int = 0

    var tutorialVector: BlochVector?

    var canGoToPreviousStep: Bool {
        stepIndex(currentStep) > 0
    }

    var canGoToNextReachedStep: Bool {
        stepIndex(currentStep) < furthestReachedIndex
    }

    func start() {
        isActive = true
        furthestReachedIndex = 0
        currentStep = .intro1
        setVector(.zero)
        showNextButton = false
        gateEnabled = false
    }

    func advanceStep() {
        let currentIndex = stepIndex(currentStep)
        let nextIndex = currentIndex + 1

        if nextIndex < TutorialStep.allCases.count {
            setStep(TutorialStep.allCases[nextIndex])
        } else {
            end()
        }
    }

    func goToPreviousStep() {
        let currentIndex = stepIndex(currentStep)
        let previousIndex = currentIndex - 1
        guard previousIndex >= 0 else { return }

        setStep(TutorialStep.allCases[previousIndex])
    }

    func goToNextReachedStep() {
        let currentIndex = stepIndex(currentStep)
        let nextIndex = currentIndex + 1

        guard nextIndex <= furthestReachedIndex,
              nextIndex < TutorialStep.allCases.count else { return }

        setStep(TutorialStep.allCases[nextIndex])
    }

    func end() {
        withAnimation {
            isActive = false
            clearVector()
        }
    }

    func handleGateTap(_ gate: QuantumGate, vectorAnimator: VectorAnimator) {
        guard gateEnabled else { return }
        guard currentStep.targetGate == gate else { return }

        gateEnabled = false
        showNextButton = false

        Task {
            guard let currentVector = tutorialVector else { return }
            let startVector = currentVector.vector
            let (axis, totalAngle) = gate.blochRotation

            let duration: Double = 0.6
            let fps: Double = 60
            let totalFrames = Int(duration * fps)

            for frame in 0...totalFrames {
                let progress = Double(frame) / Double(totalFrames)
                let t = 1.0 - pow(1.0 - progress, 3.0)
                let currentAngle = totalAngle * t

                let rotated = vectorAnimator.rotate(vector: startVector, axis: axis, angle: currentAngle)

                await MainActor.run {
                    self.setVector(BlochVector(rotated))
                }

                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / fps))
            }

            await MainActor.run {
                self.showNextButton = true
            }
        }
    }

    func setVector(_ vector: BlochVector) {
        self.tutorialVector = vector
    }

    func clearVector() {
        self.tutorialVector = nil
    }

    func enableGate() {
        gateEnabled = true
    }

    func enableNextButton() {
        showNextButton = true
    }

    private func setStep(_ step: TutorialStep) {
        currentStep = step
        setVector(step.initialVector)
        gateEnabled = false
        showNextButton = false
        updateFurthestReachedIndex()
    }

    private func stepIndex(_ step: TutorialStep) -> Int {
        TutorialStep.allCases.firstIndex(of: step) ?? 0
    }

    private func updateFurthestReachedIndex() {
        let currentIndex = stepIndex(currentStep)
        if currentIndex > furthestReachedIndex {
            furthestReachedIndex = currentIndex
        }
    }
}
