//
//  ManageView.swift
//  moov
//

import SwiftUI
import SwiftData

/// "관리" 탭 — 템플릿/종목 카탈로그/태그 카탈로그 진입점. docs/information-architecture.md.
struct ManageView: View {
    @State private var isShowingOnboarding = false
    @State private var isShowingReleaseNotes = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    TemplateListView()
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

                Section("도움말") {
                    Button {
                        isShowingOnboarding = true
                    } label: {
                        Label("온보딩 다시 보기", systemImage: "questionmark.circle")
                    }

                    Button {
                        isShowingReleaseNotes = true
                    } label: {
                        Label("업데이트 노트", systemImage: "sparkles")
                    }

                    NavigationLink {
                        VersionInfoView()
                    } label: {
                        Label("버전 정보", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("관리")
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            GuidePagerView(pages: OnboardingContent.pages, finishButtonTitle: "닫기", showsSkip: false) {
                isShowingOnboarding = false
            }
        }
        .fullScreenCover(isPresented: $isShowingReleaseNotes) {
            GuidePagerView(
                pages: ReleaseNotesContent.notes.flatMap(\.pages),
                finishButtonTitle: "닫기",
                showsSkip: false
            ) {
                isShowingReleaseNotes = false
            }
        }
    }
}

#Preview {
    ManageView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
