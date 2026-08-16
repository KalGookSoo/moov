//
//  PRTimelineCalculatorTests.swift
//  moovTests
//

import Testing
import Foundation
@testable import moov

struct PRTimelineCalculatorTests {
    @Test func marksOnlyRecordBreakingEntries() {
        let exercise = Exercise(name: "Back Squat")
        let day1 = Date(timeIntervalSince1970: 0)
        let day2 = Date(timeIntervalSince1970: 86_400)
        let day3 = Date(timeIntervalSince1970: 172_800)

        let r1 = PersonalRecord(exercise: exercise, weight: 100, weightUnit: .lb, date: day1)
        let r2 = PersonalRecord(exercise: exercise, weight: 90, weightUnit: .lb, date: day2)   // 낮은 값 - 갱신 아님
        let r3 = PersonalRecord(exercise: exercise, weight: 110, weightUnit: .lb, date: day3)  // 갱신

        // 입력 순서를 일부러 섞어서, 계산이 날짜 기준으로 재정렬하는지도 함께 확인한다.
        let timeline = PRTimelineCalculator.makeTimeline(from: [r2, r3, r1])

        #expect(timeline.count == 3)
        #expect(timeline[0].record.date == day1)
        #expect(timeline[0].isRecordBreaking == true)
        #expect(timeline[1].record.date == day2)
        #expect(timeline[1].isRecordBreaking == false)
        #expect(timeline[2].record.date == day3)
        #expect(timeline[2].isRecordBreaking == true)
    }

    @Test func emptyInputProducesEmptyTimeline() {
        #expect(PRTimelineCalculator.makeTimeline(from: []).isEmpty)
    }

    @Test func equalWeightIsNotARecordBreak() {
        let exercise = Exercise(name: "Deadlift")
        let day1 = Date(timeIntervalSince1970: 0)
        let day2 = Date(timeIntervalSince1970: 86_400)

        let r1 = PersonalRecord(exercise: exercise, weight: 100, weightUnit: .kg, date: day1)
        let r2 = PersonalRecord(exercise: exercise, weight: 100, weightUnit: .kg, date: day2)

        let timeline = PRTimelineCalculator.makeTimeline(from: [r1, r2])

        #expect(timeline[0].isRecordBreaking == true)
        #expect(timeline[1].isRecordBreaking == false)
    }
}
