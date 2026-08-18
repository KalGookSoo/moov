//
//  WorkoutImporterTests.swift
//  moovTests
//

import Testing
import Foundation
import SwiftData
@testable import moov

struct WorkoutImporterTests {
    @Test @MainActor func importsSessionWithGroupsAndCreatesCatalogEntries() throws {
        let context = TestSupport.makeContext()

        let payload = WorkoutImportPayload(sessions: [
            ImportSession(
                date: "2026-08-18",
                notes: nil,
                parts: [
                    ImportPart(
                        format: "rounds",
                        timeCapSeconds: nil,
                        groups: [
                            ImportGroup(rounds: 3, blocks: [
                                ImportBlock(
                                    exercise: "Rumanian Deadlift",
                                    weight: 45,
                                    weightUnit: "lb",
                                    reps: 10,
                                    repsUnit: nil,
                                    restSeconds: nil,
                                    tags: ["웜업"]
                                ),
                                ImportBlock(
                                    exercise: "Row",
                                    weight: nil,
                                    weightUnit: nil,
                                    reps: 40,
                                    repsUnit: "calorie",
                                    restSeconds: nil,
                                    tags: nil
                                ),
                            ])
                        ]
                    )
                ]
            )
        ])

        let count = try WorkoutImporter.apply(payload, using: context)

        #expect(count == 1)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
        let part = try #require(sessions.first?.parts.first)
        #expect(part.format == .rounds)
        let group = try #require(part.groups.first)
        #expect(group.rounds == 3)
        #expect(group.blocks.count == 2)

        let rdlBlock = try #require(group.blocks.first { $0.exerciseName == "Rumanian Deadlift" })
        #expect(rdlBlock.weight == 45)
        #expect(rdlBlock.weightUnit == .lb)
        #expect(rdlBlock.tags.map(\.name) == ["웜업"])

        let rowBlock = try #require(group.blocks.first { $0.exerciseName == "Row" })
        #expect(rowBlock.reps == 40)
        #expect(rowBlock.repsUnit == .calorie)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 2)
        let tags = try context.fetch(FetchDescriptor<moov.Tag>())
        #expect(tags.count == 1)
    }

    @Test @MainActor func reusesExistingExerciseCaseInsensitively() throws {
        let context = TestSupport.makeContext()
        let existing = Exercise(name: "back squat")
        context.insert(existing)

        let payload = WorkoutImportPayload(sessions: [
            ImportSession(date: "2026-08-18", notes: nil, parts: [
                ImportPart(format: "strength", timeCapSeconds: nil, groups: [
                    ImportGroup(rounds: 5, blocks: [
                        ImportBlock(exercise: "Back Squat", weight: 100, weightUnit: "kg", reps: 5, repsUnit: nil, restSeconds: nil, tags: nil)
                    ])
                ])
            ])
        ])

        try WorkoutImporter.apply(payload, using: context)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1)
        let block = try #require(exercises.first?.exerciseBlocks.first)
        #expect(block.exercise?.name == "back squat")
    }

    @Test @MainActor func invalidFormatInsertsNothing() throws {
        let context = TestSupport.makeContext()

        let payload = WorkoutImportPayload(sessions: [
            ImportSession(date: "2026-08-18", notes: nil, parts: [
                ImportPart(format: "not-a-real-format", timeCapSeconds: nil, groups: [
                    ImportGroup(rounds: 1, blocks: [
                        ImportBlock(exercise: "Deadlift", weight: nil, weightUnit: nil, reps: nil, repsUnit: nil, restSeconds: nil, tags: nil)
                    ])
                ])
            ])
        ])

        #expect(throws: WorkoutImportError.self) {
            try WorkoutImporter.apply(payload, using: context)
        }

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.isEmpty)
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.isEmpty)
    }

    @Test @MainActor func emptySessionsThrows() throws {
        let context = TestSupport.makeContext()
        let payload = WorkoutImportPayload(sessions: [])

        #expect(throws: WorkoutImportError.self) {
            try WorkoutImporter.apply(payload, using: context)
        }
    }

    @Test @MainActor func invalidDateThrowsAndInsertsNothing() throws {
        let context = TestSupport.makeContext()
        let payload = WorkoutImportPayload(sessions: [
            ImportSession(date: "18/08/2026", notes: nil, parts: [
                ImportPart(format: "emom", timeCapSeconds: nil, groups: [
                    ImportGroup(rounds: 1, blocks: [
                        ImportBlock(exercise: "Deadlift", weight: nil, weightUnit: nil, reps: nil, repsUnit: nil, restSeconds: nil, tags: nil)
                    ])
                ])
            ])
        ])

        #expect(throws: WorkoutImportError.self) {
            try WorkoutImporter.apply(payload, using: context)
        }
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.isEmpty)
    }
}
