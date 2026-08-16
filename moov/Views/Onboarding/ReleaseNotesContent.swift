//
//  ReleaseNotesContent.swift
//  moov
//

import Foundation

/// 버전별 업데이트 안내 콘텐츠. FR-15.
struct ReleaseNote: Identifiable {
    let id = UUID()
    let version: String
    let pages: [OnboardingPage]
}

/// 앱 번들 내 정적 데이터로 관리하는 버전별 변경 사항. 새 버전을 출시할 때마다 항목을 추가한다.
enum ReleaseNotesContent {
    static let notes: [ReleaseNote] = [
        ReleaseNote(
            version: "1.0",
            pages: [
                OnboardingPage(
                    systemImage: "sparkles",
                    title: "moov 첫 출시",
                    description: "운동 세션 기록, 히스토리, PR 관리 기능으로 moov를 시작합니다."
                )
            ]
        )
    ]
}
