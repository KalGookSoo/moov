//
//  BackupExporterTests.swift
//  moovTests
//

import Testing
import Foundation
import SwiftData
@testable import moov

struct BackupExporterTests {
    @Test @MainActor func exportsFullGraphAsDecodableJSON() throws {
        let context = TestSupport.makeContext()

        let exercise = Exercise(name: "Back Squat", category: "강화")
        context.insert(exercise)
        let tag = moov.Tag(name: "본운동")
        context.insert(tag)

        let session = WorkoutSession(date: Date(timeIntervalSince1970: 0), notes: "메모")
        context.insert(session)
        let part = WorkoutPart(order: 0, format: .strength)
        context.insert(part)
        session.parts.append(part)
        part.session = session

        let group = BlockGroup(order: 0, rounds: 5)
        context.insert(group)
        part.groups.append(group)
        group.part = part

        let block = ExerciseBlock(order: 0, exercise: exercise, weight: 100, weightUnit: .kg, reps: 5, tags: [tag])
        context.insert(block)
        group.blocks.append(block)
        block.group = group

        let result = WorkoutResult(kind: .maxWeight, maxWeight: 100)
        context.insert(result)
        part.result = result
        result.part = part

        let record = PersonalRecord(exercise: exercise, weight: 120, weightUnit: .kg, date: Date(timeIntervalSince1970: 1_000))
        context.insert(record)

        let template = WorkoutTemplate(name: "템플릿")
        context.insert(template)
        let templatePart = TemplatePart(order: 0, format: .emom)
        context.insert(templatePart)
        template.templateParts.append(templatePart)
        templatePart.template = template
        let templateGroup = TemplateBlockGroup(order: 0, rounds: 1)
        context.insert(templateGroup)
        templatePart.groups.append(templateGroup)
        templateGroup.templatePart = templatePart
        let templateBlock = TemplateBlock(order: 0, exercise: exercise, reps: 10)
        context.insert(templateBlock)
        templateGroup.blocks.append(templateBlock)
        templateBlock.group = templateGroup

        let data = try BackupExporter.makeBackupData(using: context)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)

        #expect(payload.version == 1)
        #expect(payload.exercises.count == 1)
        #expect(payload.tags.count == 1)
        #expect(payload.sessions.count == 1)
        #expect(payload.personalRecords.count == 1)
        #expect(payload.templates.count == 1)

        let exportedSession = try #require(payload.sessions.first)
        #expect(exportedSession.notes == "메모")
        let exportedPart = try #require(exportedSession.parts.first)
        #expect(exportedPart.format == .strength)
        #expect(exportedPart.result?.kind == .maxWeight)
        #expect(exportedPart.result?.maxWeight == 100)
        let exportedGroup = try #require(exportedPart.groups.first)
        #expect(exportedGroup.rounds == 5)
        let exportedBlock = try #require(exportedGroup.blocks.first)
        #expect(exportedBlock.exerciseId == exercise.id)
        #expect(exportedBlock.weight == 100)
        #expect(exportedBlock.weightUnit == .kg)
        #expect(exportedBlock.tagIds == [tag.id])

        let exportedRecord = try #require(payload.personalRecords.first)
        #expect(exportedRecord.exerciseId == exercise.id)
        #expect(exportedRecord.weight == 120)

        let exportedTemplate = try #require(payload.templates.first)
        #expect(exportedTemplate.name == "템플릿")
        #expect(exportedTemplate.parts.first?.groups.first?.blocks.first?.exerciseId == exercise.id)
    }

    @Test @MainActor func exportsEmptyDataWithoutThrowing() throws {
        let context = TestSupport.makeContext()

        let data = try BackupExporter.makeBackupData(using: context)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)

        #expect(payload.sessions.isEmpty)
        #expect(payload.exercises.isEmpty)
        #expect(payload.templates.isEmpty)
    }
}
