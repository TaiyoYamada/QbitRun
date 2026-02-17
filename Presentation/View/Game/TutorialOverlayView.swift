import SwiftUI
import simd

extension Notification.Name {
    static let tutorialGateTapped = Notification.Name("tutorialGateTapped")
}

struct TypewriterText: View {
    let text: String
    @State private var displayedText: String = ""
    @State private var charIndex: Int = 0

    var body: some View {
        Text(displayedText)
            .font(.system(size: 18, weight: .medium, design: .monospaced))
            .lineSpacing(4)
            .foregroundStyle(.white)
            .shadow(color: .cyan.opacity(0.8), radius: 2)
            .onChange(of: text) { _, newValue in
                startTyping(newValue)
            }
            .onAppear {
                startTyping(text)
            }
    }

    private func startTyping(_ newText: String) {
        displayedText = ""
        charIndex = 0

        Task {
            for char in newText {
                if newText != text { break }
                displayedText.append(char)
                let randomDelay = UInt64(Double.random(in: 0.01...0.05) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: randomDelay)
            }
        }
    }
}

struct TutorialOverlayView: View {
    @Bindable var viewModel: GameViewModel
    let spotlightFrames: [CGRect]

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Text(viewModel.currentTutorialStep.title)
                    .font(.system(size: 45, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .cyan, radius: 10)
                    .padding(.top, 10)

                TypewriterText(text: viewModel.currentTutorialStep.instruction)
                    .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyan.opacity(0.7), lineWidth: 1)
                    )
                    .frame(maxWidth: 700)
            }

            Spacer()

            Button(action: {
                viewModel.advanceTutorialStep()
            }) {
                HStack(spacing: 15) {
                    Text(viewModel.currentTutorialStep == .finish ? "INITIALIZE_GAME" : "NEXT_STEP")
                        .font(.system(size: 30, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(viewModel.showTutorialNextButton ? .black : .white.opacity(0.3))
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(
                    ZStack {
                        if viewModel.showTutorialNextButton {
                            Color.cyan
                            Color.white.opacity(0.2)
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(viewModel.showTutorialNextButton ? Color.white : Color.gray.opacity(0.5), lineWidth: 2)
                )
                .shadow(color: viewModel.showTutorialNextButton ? .cyan : .clear, radius: 10)
            }
            .disabled(!viewModel.showTutorialNextButton)
            .animation(.easeIn, value: viewModel.showTutorialNextButton)
            .padding(.bottom, 70)
        }
    }
}
