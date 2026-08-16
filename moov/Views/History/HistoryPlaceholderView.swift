//
//  HistoryPlaceholderView.swift
//  moov
//

import SwiftUI

/// UC-03(종목별/태그별 기록 추이 조회)이 구현되기 전까지의 임시 화면.
struct HistoryPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("히스토리는 준비 중이에요", systemImage: "chart.line.uptrend.xyaxis")
            } description: {
                Text("종목별·태그별 기록 추이를 곧 확인할 수 있어요.")
            }
            .navigationTitle("히스토리")
        }
    }
}

#Preview {
    HistoryPlaceholderView()
}
