//
//  ContentView.swift
//  moov
//
//  Created by doyevskyi on 8/16/26.
//

import SwiftUI
import SwiftData

/// 앱 최상위 탭 구조. docs/information-architecture.md 참고.
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lastSeenAppVersion") private var lastSeenAppVersion = ""

    @State private var presentedGuide: GuidePresentation?

    var body: some View {
        TabView {
            SessionListView()
                .tabItem {
                    Label("세션", systemImage: "figure.strengthtraining.traditional")
                }

            HistoryView()
                .tabItem {
                    Label("히스토리", systemImage: "chart.line.uptrend.xyaxis")
                }

            PersonalRecordListView()
                .tabItem {
                    Label("PR", systemImage: "trophy")
                }

            ManageView()
                .tabItem {
                    Label("관리", systemImage: "gearshape")
                }
        }
        .onAppear(perform: checkForGuideToShow)
        .fullScreenCover(item: $presentedGuide) { guide in
            GuidePagerView(
                pages: pages(for: guide),
                finishButtonTitle: guide == .onboarding ? "시작하기" : "확인"
            ) {
                complete(guide)
            }
        }
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// 마지막으로 확인한 버전보다 최신인 업데이트 노트만 모아 온보딩과 동일한 페이지 형식으로 반환한다.
    private var pendingReleaseNotePages: [OnboardingPage] {
        ReleaseNotesContent.notes
            .filter { $0.version.isVersion(greaterThan: lastSeenAppVersion) }
            .flatMap(\.pages)
    }

    private func pages(for guide: GuidePresentation) -> [OnboardingPage] {
        switch guide {
        case .onboarding: OnboardingContent.pages
        case .releaseNotes: pendingReleaseNotePages
        }
    }

    private func checkForGuideToShow() {
        guard presentedGuide == nil else { return }
        if !hasCompletedOnboarding {
            presentedGuide = .onboarding
        } else if !pendingReleaseNotePages.isEmpty {
            presentedGuide = .releaseNotes
        }
    }

    private func complete(_ guide: GuidePresentation) {
        hasCompletedOnboarding = true
        lastSeenAppVersion = currentAppVersion
        presentedGuide = nil
    }
}

private enum GuidePresentation: String, Identifiable {
    case onboarding
    case releaseNotes
    var id: String { rawValue }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
