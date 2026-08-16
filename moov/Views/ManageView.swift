//
//  ManageView.swift
//  moov
//

import SwiftUI
import SwiftData

/// "관리" 탭 — 템플릿/종목 카탈로그/태그 카탈로그 진입점. docs/information-architecture.md.
struct ManageView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    TemplatePlaceholderView()
                } label: {
                    Label("템플릿", systemImage: "doc.on.doc")
                }

                NavigationLink {
                    ExerciseCatalogView()
                } label: {
                    Label("종목 카탈로그", systemImage: "figure.run")
                }

                NavigationLink {
                    TagCatalogView()
                } label: {
                    Label("태그 카탈로그", systemImage: "tag")
                }
            }
            .navigationTitle("관리")
        }
    }
}

#Preview {
    ManageView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
