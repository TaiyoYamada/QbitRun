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
            // 背景
            // 背景
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // ヘッダー
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    Text("Records")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // バランス用の透明ボタン
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // 難易度タブ
                HStack(spacing: 0) {
                    ForEach(GameDifficulty.allCases, id: \.self) { difficulty in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDifficulty = difficulty
                            }
                        }) {
                            VStack(spacing: 4) {
                                Text("\(difficulty.emoji) \(difficulty.displayName)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(selectedDifficulty == difficulty ? .white : .white.opacity(0.5))
                                
                                // アンダーライン
                                Rectangle()
                                    .fill(selectedDifficulty == difficulty ? Color(red: 0.6, green: 0.4, blue: 1.0) : .clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 24)
                
                if scores.isEmpty {
                    Spacer()
                    Text("No records yet")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                } else {
                    List(scores.indices, id: \.self) { index in
                        let score = scores[index]
                        HStack {
                            Text("#\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(score.score) pts")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                
                                Text("\(score.problemsSolved) problems solved")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .task {
            easyScores = await scoreRepository.fetchTopScores(for: .easy)
            hardScores = await scoreRepository.fetchTopScores(for: .hard)
        }
    }
}

#Preview("記録画面") {
    RecordsView(
        scoreRepository: ScoreRepository(),
        onBack: { print("Back") }
    )
}
