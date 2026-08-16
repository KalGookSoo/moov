//
//  TemplatePlaceholderView.swift
//  moov
//

import SwiftUI

/// UC-06(운동 프로그램 템플릿 관리)이 구현되기 전까지의 임시 화면.
struct TemplatePlaceholderView: View {
    var body: some View {
        ContentUnavailableView {
            Label("템플릿은 준비 중이에요", systemImage: "doc.on.doc")
        } description: {
            Text("자주 쓰는 운동 구성을 템플릿으로 저장하는 기능을 곧 만나보실 수 있어요.")
        }
        .navigationTitle("템플릿")
    }
}

#Preview {
    NavigationStack {
        TemplatePlaceholderView()
    }
}
