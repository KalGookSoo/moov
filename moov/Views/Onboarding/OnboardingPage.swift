//
//  OnboardingPage.swift
//  moov
//

import Foundation

/// 온보딩/업데이트 안내에서 공통으로 쓰는 한 페이지 단위 콘텐츠. FR-14, FR-15.
struct OnboardingPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let description: String
}

/// 최초 실행 온보딩 콘텐츠 — 세션/히스토리/PR/관리 각 탭을 소개한다. FR-14.
enum OnboardingContent {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "figure.strengthtraining.traditional",
            title: "세션",
            description: "오늘의 운동을 파트 단위로 기록하고, 태그로 웜업·본운동·보조운동을 구분해보세요."
        ),
        OnboardingPage(
            systemImage: "chart.line.uptrend.xyaxis",
            title: "히스토리",
            description: "종목별 무게 추이와 태그별 볼륨 추이를 그래프로 확인할 수 있어요."
        ),
        OnboardingPage(
            systemImage: "trophy",
            title: "PR",
            description: "종목별 최고 기록을 등록하고 갱신 이력을 추적해보세요."
        ),
        OnboardingPage(
            systemImage: "gearshape",
            title: "관리",
            description: "템플릿, 운동 종목, 태그를 자유롭게 추가하고 관리할 수 있어요."
        ),
    ]
}
