//
//  textfont.swift
//  QuantumGateGame
//
//  Created by 山田大陽 on 2025/12/29.
//

/// font確認用ファイル
import SwiftUI

struct FontListView: View {

    private let fontNames: [String] = {
        UIFont.familyNames
            .sorted()
            .flatMap { family in
                UIFont.fontNames(forFamilyName: family).sorted()
            }
    }()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(fontNames, id: \.self) { fontName in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fontName)
                            .font(.custom(fontName, size: 18))

                        Text(fontName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    Divider()
                }
            }
            .padding()
        }
    }
}

#Preview {
    FontListView()
}
