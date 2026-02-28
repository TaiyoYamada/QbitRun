import SwiftUI

struct TypewriterText: View {
    let attributedText: AttributedString
    let plainText: String
    var onFinished: (() -> Void)? = nil
    @State private var revealedCount: Int = 0
    @State private var typingTask: Task<Void, Never>? = nil

    private let lineSpacing: CGFloat = 2

    init(attributedText: AttributedString, onFinished: (() -> Void)? = nil) {
        self.attributedText = attributedText
        self.plainText = String(attributedText.characters)
        self.onFinished = onFinished
    }

    var body: some View {
        OutlinedInstructionTextView(
            attributedText: revealedAttributedText,
            lineSpacing: lineSpacing
        )        
        .dynamicTypeSize(.small ... .large)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plainText.voiceOverFriendlyTutorialText)
        .onChange(of: plainText) { _, _ in
            startTyping()
        }
        .onAppear {
            startTyping()
        }
        .onDisappear {
            typingTask?.cancel()
            typingTask = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .skipTutorialTyping)) { _ in
            completeTypingInstantly()
        }
    }

    private var revealedAttributedText: AttributedString {
        guard revealedCount > 0 else { return AttributedString("") }
        let chars = attributedText.characters
        let endIdx = chars.index(chars.startIndex, offsetBy: min(revealedCount, chars.count))
        return AttributedString(attributedText[chars.startIndex..<endIdx])
    }

    private func startTyping() {
        typingTask?.cancel()
        revealedCount = 0
        let totalCount = attributedText.characters.count
        guard totalCount > 0 else {
            onFinished?()
            return
        }

        typingTask = Task { @MainActor in
            for i in 1...totalCount {
                if Task.isCancelled { return }
                revealedCount = i
                let randomDelay = UInt64(Double.random(in: 0.01...0.05) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: randomDelay)
            }
            guard !Task.isCancelled else { return }
            onFinished?()
        }
    }

    private func completeTypingInstantly() {
        typingTask?.cancel()
        let totalCount = attributedText.characters.count
        if revealedCount < totalCount {
            revealedCount = totalCount
            onFinished?()
        }
    }
}
