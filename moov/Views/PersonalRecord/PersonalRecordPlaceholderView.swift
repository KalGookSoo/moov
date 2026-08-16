//
//  PersonalRecordPlaceholderView.swift
//  moov
//

import SwiftUI

/// UC-04(PR 관리)가 구현되기 전까지의 임시 화면.
struct PersonalRecordPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("PR은 준비 중이에요", systemImage: "trophy")
            } description: {
                Text("종목별 1RM을 등록하고 갱신 이력을 곧 확인할 수 있어요.")
            }
            .navigationTitle("PR")
        }
    }
}

#Preview {
    PersonalRecordPlaceholderView()
}
