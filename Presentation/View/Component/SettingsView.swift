// SPDX-License-Identifier: MIT
// Presentation/View/Component/SettingsView.swift

import SwiftUI

struct SettingsView: View {
    
    @Bindable var audioManager: AudioManager
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background Dim
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Modal Content
            VStack(spacing: 30) {
                Text("SETTING")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white)
                    .shadow(color: .cyan.opacity(0.5), radius: 10)

                VStack(spacing: 24) {
                    // BGM Volume
                    VolumeSlider(
                        label: "BGM",
                        value: $audioManager.bgmVolume,
                        icon: "music.note"
                    )
                    
                    // SFX Volume
                    VolumeSlider(
                        label: "SE",
                        value: $audioManager.sfxVolume,
                        icon: "speaker.wave.2.fill"
                    )
                }
                .padding(.horizontal, 20)
                
                // Close Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onDismiss()
                }) {
                    Text("CLOSE")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 60))
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
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
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.cyan)
                Text(label)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text("\(Int(value * 100))")
                    .font(.system(size: 25, weight: .black, design: .rounded))
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
