//
//  BackupImporterTests.swift
//  moovTests
//

import Testing
import Foundation
import SwiftData
@testable import moov

struct BackupImporterTests {
    @Test @MainActor func roundTripsExportedDataIntoFreshContext() throws {
        let sourceContext = TestSupport.makeContext()
        let exercise = Exercise(name: "Back Squat", category: "강화")
        sourceContext.insert(exercise)
        let tag = moov.Tag(name: "본운동")
        sourceContext.insert(tag)

        let session = WorkoutSession(date: Date(timeIntervalSince1970: 0), notes: "메모")
        sourceContext.insert(session)
        let part = WorkoutPart(order: 0, format: .strength)
        sourceContext.insert(part)
        session.parts.append(part)
        part.session = session
        let group = BlockGroup(order: 0, rounds: 5)
        sourceContext.insert(group)
        part.groups.append(group)
        group.part = part
        let block = ExerciseBlock(order: 0, exercise: exercise, weight: 100, weightUnit: .kg, reps: 5, tags: [tag])
        sourceContext.insert(block)
        group.blocks.append(block)
        block.group = group

        let data = try BackupExporter.makeBackupData(using: sourceContext)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)

        let destinationContext = TestSupport.makeContext()
        #expect(try BackupImporter.hasExistingData(using: destinationContext) == false)

        let importedCount = try BackupImporter.apply(payload, strategy: .merge, using: destinationContext)

        #expect(importedCount == 1)
        let sessions = try destinationContext.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.notes == "메모")
        let restoredBlock = try #require(sessions.first?.parts.first?.groups.first?.blocks.first)
        #expect(restoredBlock.exercise?.name == "Back Squat")
        #expect(restoredBlock.weight == 100)
        #expect(restoredBlock.tags.map(\.name) == ["본운동"])

        let exercises = try destinationContext.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1)
    }

    @Test @MainActor func mergeReusesExistingExerciseByName() throws {
        let context = TestSupport.makeContext()
        let existingExercise = Exercise(name: "Back Squat")
        context.insert(existingExercise)

        let payload = BackupPayload(
            version: 1,
            exportedAt: .now,
            exercises: [BackupExercise(id: UUID(), name: "Back Squat", category: nil, defaultWeightUnit: nil)],
            tags: [],
            sessions: [
                BackupSession(
                    id: UUID(),
                    date: Date(timeIntervalSince1970: 0),
                    notes: nil,
                    conditionNotes: [],
                    parts: [
                        BackupPart(
                            id: UUID(),
                            order: 0,
                            format: .strength,
                            timeCapSeconds: nil,
                            result: nil,
                            groups: [
                                BackupGroup(id: UUID(), order: 0, rounds: 1, blocks: [
                                    BackupBlock(
                                        id: UUID(),
                                        order: 0,
                                        exerciseId: nil,
                                        exerciseName: "Back Squat",
                                        weight: nil,
                                        weightUnit: nil,
                                        reps: nil,
                                        repsUnit: nil,
                                        restSeconds: nil,
                                        tagIds: []
                                    )
                                ])
                            ]
                        )
                    ]
                )
            ],
            personalRecords: [],
            templates: []
        )

        try BackupImporter.apply(payload, strategy: .merge, using: context)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1)
        #expect(exercises.first === existingExercise)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
        let restoredBlock = try #require(sessions.first?.parts.first?.groups.first?.blocks.first)
        #expect(restoredBlock.exercise === existingExercise)
    }

    @Test @MainActor func mergeSkipsAlreadyImportedSession() throws {
        let context = TestSupport.makeContext()
        let sessionID = UUID()
        let payload = BackupPayload(
            version: 1,
            exportedAt: .now,
            exercises: [],
            tags: [],
            sessions: [
                BackupSession(id: sessionID, date: Date(timeIntervalSince1970: 0), notes: nil, conditionNotes: [], parts: [])
            ],
            personalRecords: [],
            templates: []
        )

        let firstImportCount = try BackupImporter.apply(payload, strategy: .merge, using: context)
        let secondImportCount = try BackupImporter.apply(payload, strategy: .merge, using: context)

        #expect(firstImportCount == 1)
        #expect(secondImportCount == 0)
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
    }

    @Test @MainActor func replaceDeletesExistingDataFirst() throws {
        let context = TestSupport.makeContext()
        let staleExercise = Exercise(name: "Stale Exercise")
        context.insert(staleExercise)
        let staleSession = WorkoutSession(date: .now)
        context.insert(staleSession)

        let payload = BackupPayload(
            version: 1,
            exportedAt: .now,
            exercises: [BackupExercise(id: UUID(), name: "Fresh Exercise", category: nil, defaultWeightUnit: nil)],
            tags: [],
            sessions: [],
            personalRecords: [],
            templates: []
        )

        try BackupImporter.apply(payload, strategy: .replace, using: context)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.map(\.name) == ["Fresh Exercise"])
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.isEmpty)
    }
}
