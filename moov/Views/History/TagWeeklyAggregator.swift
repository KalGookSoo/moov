//
//  TagWeeklyAggregator.swift
//  moov
//

import Foundation

/// 특정 태그가 부여된 블록의 주간 집계 한 건.
struct WeeklyBucket: Identifiable {
    let weekStart: Date
    let volume: Int
    let frequency: Int

    var id: Date { weekStart }
}

/// docs/testing-strategy.md 유닛 테스트 대상. UC-03, FR-13.
enum TagWeeklyAggregator {
    /// 태그가 부여되고 세션에 속한 블록만 골라 날짜 오름차순으로 정렬한다.
    static func matchingEntries(blocks: [ExerciseBlock], tag: Tag) -> [(date: Date, block: ExerciseBlock)] {
        blocks
            .compactMap { block in
                guard block.tags.contains(where: { $0.id == tag.id }),
                      let date = block.part?.session?.date else { return nil }
                return (date, block)
            }
            .sorted { $0.date < $1.date }
    }

    /// 기간(주) 단위로 볼륨(세트×렙 합)과 빈도(블록 수)를 집계한다.
    static func aggregate(blocks: [ExerciseBlock], tag: Tag, calendar: Calendar = .current) -> [WeeklyBucket] {
        let entries = matchingEntries(blocks: blocks, tag: tag)
        var buckets: [Date: (volume: Int, frequency: Int)] = [:]

        for entry in entries {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start ?? entry.date
            let reps = entry.block.reps ?? 0
            let sets = entry.block.sets ?? 1
            var bucket = buckets[weekStart] ?? (volume: 0, frequency: 0)
            bucket.volume += reps * sets
            bucket.frequency += 1
            buckets[weekStart] = bucket
        }

        return buckets
            .map { WeeklyBucket(weekStart: $0.key, volume: $0.value.volume, frequency: $0.value.frequency) }
            .sorted { $0.weekStart < $1.weekStart }
    }
}
