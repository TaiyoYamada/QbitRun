import SwiftUI
import UIKit

struct GameHeaderView: View {
    let remainingTime: Int
    let score: Int
    let isTimeLow: Bool
    let isTutorialActive: Bool
    let onExitTapped: () -> Void

    private var scoreColor: AnyShapeStyle {
        switch score {
        case 30000...:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white, .cyan, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case 10000...:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case 5000...:
            return AnyShapeStyle(.purple)
        case 1000...:
            return AnyShapeStyle(.cyan)
        default:
            return AnyShapeStyle(.white)
        }
    }

    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)

                Circle()
                    .trim(from: 1.0 - (CGFloat(remainingTime) / 60.0), to: 1.0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: isTimeLow ? [
                                Color(red: 1.0, green: 0.2, blue: 0.2),
                                Color(red: 0.8, green: 0.0, blue: 0.0)
                            ] : [
                                Color(red: 0.65, green: 0.95, blue: 1.0),
                                Color(red: 0.35, green: 0.50, blue: 0.95),
                                Color(red: 0.45, green: 0.20, blue: 0.70)

                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: remainingTime)

                Text(String(format: "%d", remainingTime))
                    .font(.system(size: 53, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isTimeLow ? Color(red: 1.0, green: 0.2, blue: 0.2) : .white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
            }
            .frame(width: 115, height: 115)
            .background(
                Circle()
                    .fill(.black.opacity(0.2))
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
            .anchorPreference(key: PostTutorialGuideFocusPreferenceKey.self, value: .bounds) { anchor in
                [.timer: anchor]
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Time remaining")
            .accessibilityValue("\(remainingTime) seconds")
            .accessibilityHint("Counts down while the game is active.")

            HStack {
                Text("\(score)")
                    .font(.system(size: 45, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(scoreColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: 170, height: 110, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        ZStack {
                            Color.clear
                            Color.black.opacity(0.2)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 60))
                    .overlay(
                        RoundedRectangle(cornerRadius: 60)
                            .stroke(Color(red: 0.35, green: 0.50, blue: 0.95).opacity(0.9), lineWidth: 5)
                    )
                    .padding(.leading, 30)
                    .anchorPreference(key: PostTutorialGuideFocusPreferenceKey.self, value: .bounds) { anchor in
                        [.score: anchor]
                    }
                    .accessibilityLabel("Score")
                    .accessibilityValue("\(score) points")

                Spacer()

                Button(action: {
                    onExitTapped()
                }) {
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 60, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.trailing, 20)
                .accessibilityLabel("Exit game")
                .accessibilityHint("Open exit confirmation.")
            }
        }
        .opacity(isTutorialActive ? 0 : 1)
    }
}
