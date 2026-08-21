//
//  UsageGuideListView.swift
//  moov
//

import SwiftUI

/// 이용 가이드 항목 목록. 작성이 완료된 항목만 보여준다. UC-12, FR-23.
struct UsageGuideListView: View {
    var body: some View {
        List(UsageGuideContent.topics) { topic in
            NavigationLink {
                UsageGuideDetailView(topic: topic)
            } label: {
                Text(topic.title)
            }
        }
        .navigationTitle("이용 가이드")
    }
}

#Preview {
    NavigationStack {
        UsageGuideListView()
    }
}
