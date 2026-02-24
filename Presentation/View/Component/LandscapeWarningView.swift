import SwiftUI
import UIKit

struct LandscapeWarningView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "iphone.landscape")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, options: .repeating)
                    .rotationEffect(.degrees(-90))
                
                Text("Please rotate to portrait mode")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text("Vertical orientation is required to play.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Please rotate to portrait mode. Vertical orientation is required to play.")
        }
        .zIndex(9999)
        .onAppear {
            announceForVoiceOver()
        }
    }

    private func announceForVoiceOver() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(
            notification: .screenChanged,
            argument: "Please rotate to portrait mode. Vertical orientation is required to play."
        )
    }
}

#Preview {
    LandscapeWarningView()
}
