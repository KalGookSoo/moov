//
//  UsageGuideDetailView.swift
//  moov
//

import SwiftUI

/// 이용 가이드 항목 상세. MVP 단계에서는 마크다운을 렌더링하지 않고 텍스트 그대로 보여준다. UC-12, FR-23.
struct UsageGuideDetailView: View {
    let topic: UsageGuideTopic

    var body: some View {
        ScrollView {
            Text(topic.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        UsageGuideDetailView(topic: UsageGuideContent.topics[0])
    }
}
