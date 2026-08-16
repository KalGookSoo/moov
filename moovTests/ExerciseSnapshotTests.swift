//
//  ExerciseSnapshotTests.swift
//  moovTests
//

import Testing
import SwiftData
@testable import moov

struct ExerciseSnapshotTests {
    @Test @MainActor func exerciseNameSnapshotSurvivesDeletion() throws {
        let context = TestSupport.makeContext()

        let exercise = Exercise(name: "Back Squat")
        context.insert(exercise)

        let block = ExerciseBlock(order: 0, exercise: exercise)
        context.insert(block)
        try context.save()

        context.delete(exercise)
        try context.save()

        let refetched = try #require(try context.fetch(FetchDescriptor<ExerciseBlock>()).first)
        #expect(refetched.exercise == nil)
        #expect(refetched.exerciseName == "Back Squat")
    }
}
