//
//  PRTimelineCalculator.swift
//  moov
//

import Foundation

/// PR 갱신 이력 한 건. 특정 시점까지의 누적 최댓값 기준으로 "갱신" 여부를 표시한다.
struct PRTimelineEntry: Identifiable {
    let record: PersonalRecord
    let isRecordBreaking: Bool
    var id: UUID { record.id }
}

/// docs/testing-strategy.md 유닛 테스트 대상. UC-04, FR-07.
enum PRTimelineCalculator {
    /// 오래된 순으로 정렬하고, 각 시점까지의 누적 최댓값을 기준으로 "갱신" 여부를 표시한다.
    static func makeTimeline(from records: [PersonalRecord]) -> [PRTimelineEntry] {
        let ascending = records.sorted { $0.date < $1.date }
        var runningBest = -Double.infinity
        var entries: [PRTimelineEntry] = []
        for record in ascending {
            let isRecordBreaking = record.weight > runningBest
            if isRecordBreaking { runningBest = record.weight }
            entries.append(PRTimelineEntry(record: record, isRecordBreaking: isRecordBreaking))
        }
        return entries
    }
}
