import SwiftUI

struct GameBlochSphereSection: View {
    let currentVector: BlochVector
    let targetVector: BlochVector
    let isTutorialActive: Bool
    let showCountdown: Bool
    let comboCount: Int
    let lastComboBonus: Int
    @Binding var showComboEffect: Bool
    let geometry: GeometryProxy

    private var blochSphereAccessibilityValue: String {
        let currentState = stateDescription(for: currentVector)
        guard !isTutorialActive else {
            return "Current state: \(currentState)."
        }

        let targetState = stateDescription(for: targetVector)
        let isMatching = currentVector.distance(to: targetVector) < 0.1
        let matchStatus = isMatching ? "Matched" : "Not matched"
        return "Current state: \(currentState). Target state: \(targetState). \(matchStatus)."
    }

    var body: some View {
        let size = min(geometry.size.width, geometry.size.height) * 0.85

        ZStack(alignment: .topTrailing) {
            VStack() {
                if !isTutorialActive {
                    legendView
                        .accessibilitySortPriority(100)
                }

                BlochSphereViewRepresentable(
                    vector: currentVector,
                    animated: false,
                    targetVector: isTutorialActive ? nil : targetVector,
                    showBackground: false
                )
                .frame(width: size, height: size)
                .opacity(showCountdown ? 0 : 1)
                .anchorPreference(key: SphereBoundsPreferenceKey.self, value: .bounds) { anchor in
                    anchor
                }
                .anchorPreference(key: PostTutorialGuideFocusPreferenceKey.self, value: .bounds) { anchor in
                    [.sphere: anchor]
                }
                .accessibilityHidden(true)
            }

            ComboEffectView(
                comboCount: comboCount,
                bonus: lastComboBonus,
                isVisible: $showComboEffect
            )
            .offset(x: 10, y: 110)
            .accessibilityHidden(true)
        }
        .padding(.top, -60)
        .padding(.bottom, -110)
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 10) {
            legendItem(color: Color(red: 0.9, green: 0.2, blue: 0.2), label: "CURRENT") {
                Triangle()
                    .fill(Color(red: 0.9, green: 0.2, blue: 0.2).opacity(0.8))
                    .frame(width: 25, height: 25)
            }
            legendItem(color: Color.white, label: "TARGET") {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 25, height: 25)
            }
            legendItem(color: Color(red: 1.0, green: 0.84, blue: 0.0), label: "MATCH") {
                Rectangle()
                    .fill(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(45))
                    .frame(width: 25, height: 25)
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .offset(
            x: -geometry.size.width * 0.32,
            y: geometry.size.height * 0.08
        )
    }

    private func legendItem<S: View>(color: Color, label: String, @ViewBuilder shape: () -> S) -> some View {
        HStack(spacing: 15) {
            shape()
            Text(label)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .tracking(3)
                .foregroundStyle(color.opacity(0.8))
        }
    }

    private func stateDescription(for vector: BlochVector) -> String {
        let knownStates: [(BlochVector, String)] = [
            (.zero, "ket zero"),
            (.one, "ket one"),
            (.plus, "ket plus"),
            (.minus, "ket minus"),
            (.plusI, "ket plus i"),
            (.minusI, "ket minus i")
        ]

        if let knownState = knownStates.first(where: { vector.distance(to: $0.0) < 0.12 }) {
            return knownState.1
        }

        return String(
            format: "x %.2f, y %.2f, z %.2f",
            vector.x,
            vector.y,
            vector.z
        )
    }
}

/// 凡例用の三角形シェイプ（状態ベクトルの円錐先端を2Dで表現）
private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
