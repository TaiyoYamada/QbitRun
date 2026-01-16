import SwiftUI

/// 過去の記録画面
struct RecordsView: View {
    let scoreRepository: ScoreRepository
    let onBack: () -> Void
    
    @State private var selectedDifficulty: GameDifficulty = .easy
    @State private var easyScores: [ScoreEntry] = []
    @State private var hardScores: [ScoreEntry] = []
    
    /// 現在選択中の難易度のスコア
    private var scores: [ScoreEntry] {
        selectedDifficulty == .easy ? easyScores : hardScores
    }
    
    var body: some View {
        ZStack {
            // MARK: - Layer 1: Background
            StandardBackgroundView(showGrid: true, circuitOpacity: 0.2)
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    HStack {
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            onBack()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                Text("BACK")
                                    .font(.custom("Optima-Bold", size: 16))
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    Text("FLIGHT LOG")
                        .font(.custom("Optima-Bold", size: 24))
                        .foregroundStyle(.white)
                        .tracking(2)
                        .shadow(color: .cyan.opacity(0.5), radius: 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Difficulty Tabs
                HStack(spacing: 12) {
                    DifficultyTabButton(
                        difficulty: .easy,
                        isSelected: selectedDifficulty == .easy,
                        action: { selectedDifficulty = .easy }
                    )
                    
                    DifficultyTabButton(
                        difficulty: .hard,
                        isSelected: selectedDifficulty == .hard,
                        action: { selectedDifficulty = .hard }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // List Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if scores.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(Array(scores.enumerated()), id: \.offset) { index, score in
                                ScoreRowCard(index: index, score: score)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .task {
            // データロード
            easyScores = await scoreRepository.fetchTopScores(for: .easy)
            hardScores = await scoreRepository.fetchTopScores(for: .hard)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 100)
            
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.2))
            
            Text("NO FLIGHT DATA")
                .font(.custom("Optima-Bold", size: 18))
                .foregroundStyle(.white.opacity(0.4))
                .tracking(1)
            
            Spacer()
        }
    }
}

// MARK: - Components

struct DifficultyTabButton: View {
    let difficulty: GameDifficulty
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            HStack {
                Text(difficulty.emoji)
                Text(difficulty.displayName.uppercased())
                    .font(.custom("Optima-Bold", size: 14))
            }
            .foregroundStyle(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ? Color.cyan : Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isSelected ? .cyan.opacity(0.5) : .clear, radius: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScoreRowCard: View {
    let index: Int
    let score: ScoreEntry
    
    // Top 3 Ranking Colors
    private var rankColor: Color {
        switch index {
        case 0: return .yellow
        case 1: return Color(red: 0.8, green: 0.8, blue: 0.8) // Silver
        case 2: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .white.opacity(0.6)
        }
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Rank Number
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(rankColor.opacity(0.5), lineWidth: 1))
                
                Text("\(index + 1)")
                    .font(.custom("Optima-Bold", size: 20))
                    .foregroundStyle(rankColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Score
                Text("\(score.score)")
                    .font(.custom("Optima-Bold", size: 24))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                // Details
                HStack(spacing: 12) {
                    Label("\(score.problemsSolved) solved", systemImage: "checkmark.circle.fill")
                    Label("\(score.bonusPoints) bonus", systemImage: "star.fill")
                }
                .font(.custom("Optima-Regular", size: 12))
                .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Icon (Decorative)
            Image(systemName: "flag.checkered")
                .font(.system(size: 20))
                .foregroundStyle(.white.opacity(0.1))
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview("記録画面") {
    RecordsView(
        scoreRepository: ScoreRepository(),
        onBack: { print("Back") }
    )
    .preferredColorScheme(.dark)
}
