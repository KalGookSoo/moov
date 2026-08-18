//
//  TagWeeklyAggregatorTests.swift
//  moovTests
//

import Testing
import Foundation
@testable import moov

struct TagWeeklyAggregatorTests {
    /// 타임존/1주 시작 요일에 좌우되지 않도록 고정된 캘린더를 사용한다.
    private static var fixedCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test func aggregatesVolumeAndFrequencyWithinSameWeek() {
        let tag = Tag(name: "컨디셔닝")
        let exercise = Exercise(name: "Row")

        let session = WorkoutSession(date: Date(timeIntervalSince1970: 0))
        let part = WorkoutPart(order: 0, format: .amrap)
        session.parts.append(part)
        part.session = session

        let taggedGroup1 = BlockGroup(order: 0, rounds: 3)
        let taggedBlock1 = ExerciseBlock(order: 0, exercise: exercise, reps: 10, tags: [tag])
        taggedGroup1.blocks.append(taggedBlock1)
        taggedBlock1.group = taggedGroup1

        let taggedGroup2 = BlockGroup(order: 1, rounds: 2)
        let taggedBlock2 = ExerciseBlock(order: 0, exercise: exercise, reps: 5, tags: [tag])
        taggedGroup2.blocks.append(taggedBlock2)
        taggedBlock2.group = taggedGroup2

        let untaggedGroup = BlockGroup(order: 2, rounds: 100)
        let untaggedBlock = ExerciseBlock(order: 0, exercise: exercise, reps: 100)
        untaggedGroup.blocks.append(untaggedBlock)
        untaggedBlock.group = untaggedGroup

        part.groups.append(contentsOf: [taggedGroup1, taggedGroup2, untaggedGroup])
        taggedGroup1.part = part
        taggedGroup2.part = part
        untaggedGroup.part = part

        let buckets = TagWeeklyAggregator.aggregate(
            blocks: [taggedBlock1, taggedBlock2, untaggedBlock],
            tag: tag,
            calendar: Self.fixedCalendar
        )

        #expect(buckets.count == 1)
        #expect(buckets[0].frequency == 2)
        #expect(buckets[0].volume == 10 * 3 + 5 * 2)
    }

    @Test func splitsEntriesAcrossDifferentWeeks() {
        let tag = Tag(name: "본운동")
        let exercise = Exercise(name: "Deadlift")

        let session1 = WorkoutSession(date: Date(timeIntervalSince1970: 0))
        let part1 = WorkoutPart(order: 0, format: .strength)
        session1.parts.append(part1)
        part1.session = session1
        let group1 = BlockGroup(order: 0, rounds: 5)
        let block1 = ExerciseBlock(order: 0, exercise: exercise, reps: 5, tags: [tag])
        group1.blocks.append(block1)
        block1.group = group1
        part1.groups.append(group1)
        group1.part = part1

        let twoWeeksLater = Date(timeIntervalSince1970: 0).addingTimeInterval(14 * 86_400)
        let session2 = WorkoutSession(date: twoWeeksLater)
        let part2 = WorkoutPart(order: 0, format: .strength)
        session2.parts.append(part2)
        part2.session = session2
        let group2 = BlockGroup(order: 0, rounds: 5)
        let block2 = ExerciseBlock(order: 0, exercise: exercise, reps: 5, tags: [tag])
        group2.blocks.append(block2)
        block2.group = group2
        part2.groups.append(group2)
        group2.part = part2

        let buckets = TagWeeklyAggregator.aggregate(
            blocks: [block1, block2],
            tag: tag,
            calendar: Self.fixedCalendar
        )

        #expect(buckets.count == 2)
    }

    @Test func blockWithoutSessionIsExcluded() {
        let tag = Tag(name: "스킬")
        let exercise = Exercise(name: "Handstand Walk")
        // part/session 없이 고아 상태인 블록 - 집계에서 제외되어야 한다.
        let orphanBlock = ExerciseBlock(order: 0, exercise: exercise, tags: [tag])

        let buckets = TagWeeklyAggregator.aggregate(blocks: [orphanBlock], tag: tag, calendar: Self.fixedCalendar)

        #expect(buckets.isEmpty)
    }
}
