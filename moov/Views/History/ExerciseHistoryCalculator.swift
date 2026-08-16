//
//  ExerciseHistoryCalculator.swift
//  moov
//

import Foundation

/// docs/testing-strategy.md 유닛 테스트 대상. UC-03, FR-06.
enum ExerciseHistoryCalculator {
    /// 세션에 속한 블록만 골라 날짜 오름차순으로 정렬한다.
    static func makeEntries(from blocks: [ExerciseBlock]) -> [(date: Date, block: ExerciseBlock)] {
        blocks
            .compactMap { block in
                guard let date = block.part?.session?.date else { return nil }
                return (date, block)
            }
            .sorted { $0.date < $1.date }
    }
}
