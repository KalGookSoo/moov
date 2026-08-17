//
//  TagChip.swift
//  moov
//

import SwiftUI

/// 선택된 태그를 나타내는 칩(chip). FR-19.
struct TagChip: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(.tint)
    }
}
