import SwiftUI

/// 過去の記録画面
struct RecordsView: View {
    let scoreRepository: ScoreRepository
    let onBack: () -> Void
    
    @State private var scores: [ScoreEntry] = []
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
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
            scores = await scoreRepository.fetchTopScores()
        }
    }
}

#Preview("記録画面") {
    RecordsView(
        scoreRepository: ScoreRepository(),
        onBack: { print("Back") }
    )
}
