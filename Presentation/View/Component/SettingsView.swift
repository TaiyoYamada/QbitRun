import SwiftUI

struct SettingsView: View {

    @Bindable var audioManager: AudioManager
    let onDismiss: () -> Void

    @State private var animateIn = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateIn = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss()
                    }
                }

            VStack(spacing: 60) {
                Text("SETTING")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white)
                    .shadow(color: .cyan.opacity(0.5), radius: 10)

                VStack(spacing: 24) {
                    VolumeSlider(
                        label: "BGM",
                        value: $audioManager.bgmVolume,
                        icon: "music.note"
                    )

                    VolumeSlider(
                        label: "SE",
                        value: $audioManager.sfxVolume,
                        icon: "speaker.wave.2.fill"
                    )
                }
                .padding(.horizontal, 20)

                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        animateIn = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        onDismiss()
                    }
                }) {
                    Text("CLOSE")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(.white.opacity(0.3), lineWidth: 3)
                        )
                }
                .padding(.top, 10)
            }
            .padding(50)
            .frame(width: 450)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            colors: [.cyan.opacity(0.5), .purple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
    }
}

struct VolumeSlider: View {
    let label: String
    @Binding var value: Float
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)
                Text(label)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("\(Int(value * 100))")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Slider(value: $value, in: 0...1)
                .tint(.cyan)
        }
    }
}

#Preview {
    SettingsView(audioManager: AudioManager(), onDismiss: {})
        .preferredColorScheme(.dark)
}
