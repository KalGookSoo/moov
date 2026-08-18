//
//  BackupExporter.swift
//  moov
//

import Foundation
import SwiftData

/// 백업 파일 최상위 구조. 가져오기(FR-18)에서 그대로 되읽는 왕복 전용 포맷이다.
/// docs/backup-format.md 참고. FR-17.
struct BackupPayload: Codable {
    let version: Int
    let exportedAt: Date
    let exercises: [BackupExercise]
    let tags: [BackupTag]
    let sessions: [BackupSession]
    let personalRecords: [BackupPersonalRecord]
    let templates: [BackupTemplate]
}

struct BackupExercise: Codable {
    let id: UUID
    let name: String
    let category: String?
    let defaultWeightUnit: WeightUnit?
}

struct BackupTag: Codable {
    let id: UUID
    let name: String
    let colorHex: String?
}

struct BackupConditionNote: Codable {
    let id: UUID
    let bodyPart: String?
    let painLevel: Int?
    let memo: String
}

struct BackupResult: Codable {
    let kind: ResultKind
    let timeSeconds: Int?
    let rounds: Int?
    let extraReps: Int?
    let isCompleted: Bool?
    let maxWeight: Double?
    let completionNote: String?
}

struct BackupBlock: Codable {
    let id: UUID
    let order: Int
    let exerciseId: UUID?
    let exerciseName: String
    let weight: Double?
    let weightUnit: WeightUnit?
    let reps: Int?
    let repsUnit: RepsUnit?
    let restSeconds: Int?
    let tagIds: [UUID]
}

struct BackupGroup: Codable {
    let id: UUID
    let order: Int
    let rounds: Int
    let blocks: [BackupBlock]
}

struct BackupPart: Codable {
    let id: UUID
    let order: Int
    let format: WorkoutFormat
    let timeCapSeconds: Int?
    let result: BackupResult?
    let groups: [BackupGroup]
}

struct BackupSession: Codable {
    let id: UUID
    let date: Date
    let notes: String?
    let conditionNotes: [BackupConditionNote]
    let parts: [BackupPart]
}

struct BackupPersonalRecord: Codable {
    let id: UUID
    let exerciseId: UUID?
    let exerciseName: String
    let weight: Double
    let weightUnit: WeightUnit
    let date: Date
}

struct BackupTemplateBlock: Codable {
    let id: UUID
    let order: Int
    let exerciseId: UUID?
    let exerciseName: String
    let weight: Double?
    let weightUnit: WeightUnit?
    let reps: Int?
    let repsUnit: RepsUnit?
    let restSeconds: Int?
    let tagIds: [UUID]
}

struct BackupTemplateGroup: Codable {
    let id: UUID
    let order: Int
    let rounds: Int
    let blocks: [BackupTemplateBlock]
}

struct BackupTemplatePart: Codable {
    let id: UUID
    let order: Int
    let format: WorkoutFormat
    let groups: [BackupTemplateGroup]
}

struct BackupTemplate: Codable {
    let id: UUID
    let name: String
    let parts: [BackupTemplatePart]
}

/// 전체 데이터를 백업 JSON으로 직렬화한다. FR-17.
@MainActor
enum BackupExporter {
    static func makeBackupData(using context: ModelContext) throws -> Data {
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let tags = try context.fetch(FetchDescriptor<Tag>())
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        let personalRecords = try context.fetch(FetchDescriptor<PersonalRecord>())
        let templates = try context.fetch(FetchDescriptor<WorkoutTemplate>())

        let payload = BackupPayload(
            version: 1,
            exportedAt: .now,
            exercises: exercises.map(makeBackupExercise),
            tags: tags.map(makeBackupTag),
            sessions: sessions.sorted { $0.date < $1.date }.map(makeBackupSession),
            personalRecords: personalRecords.sorted { $0.date < $1.date }.map(makeBackupPersonalRecord),
            templates: templates.map(makeBackupTemplate)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(payload)
    }

    private static func makeBackupExercise(_ exercise: Exercise) -> BackupExercise {
        BackupExercise(
            id: exercise.id,
            name: exercise.name,
            category: exercise.category,
            defaultWeightUnit: exercise.defaultWeightUnit
        )
    }

    private static func makeBackupTag(_ tag: Tag) -> BackupTag {
        BackupTag(id: tag.id, name: tag.name, colorHex: tag.colorHex)
    }

    private static func makeBackupSession(_ session: WorkoutSession) -> BackupSession {
        BackupSession(
            id: session.id,
            date: session.date,
            notes: session.notes,
            conditionNotes: session.conditionNotes.map {
                BackupConditionNote(id: $0.id, bodyPart: $0.bodyPart, painLevel: $0.painLevel, memo: $0.memo)
            },
            parts: session.parts.sorted { $0.order < $1.order }.map(makeBackupPart)
        )
    }

    private static func makeBackupPart(_ part: WorkoutPart) -> BackupPart {
        BackupPart(
            id: part.id,
            order: part.order,
            format: part.format,
            timeCapSeconds: part.timeCapSeconds,
            result: part.result.map {
                BackupResult(
                    kind: $0.kind,
                    timeSeconds: $0.timeSeconds,
                    rounds: $0.rounds,
                    extraReps: $0.extraReps,
                    isCompleted: $0.isCompleted,
                    maxWeight: $0.maxWeight,
                    completionNote: $0.completionNote
                )
            },
            groups: part.groups.sorted { $0.order < $1.order }.map(makeBackupGroup)
        )
    }

    private static func makeBackupGroup(_ group: BlockGroup) -> BackupGroup {
        BackupGroup(
            id: group.id,
            order: group.order,
            rounds: group.rounds,
            blocks: group.blocks.sorted { $0.order < $1.order }.map(makeBackupBlock)
        )
    }

    private static func makeBackupBlock(_ block: ExerciseBlock) -> BackupBlock {
        BackupBlock(
            id: block.id,
            order: block.order,
            exerciseId: block.exercise?.id,
            exerciseName: block.exerciseName,
            weight: block.weight,
            weightUnit: block.weightUnit,
            reps: block.reps,
            repsUnit: block.repsUnit,
            restSeconds: block.restSeconds,
            tagIds: block.tags.map(\.id)
        )
    }

    private static func makeBackupPersonalRecord(_ record: PersonalRecord) -> BackupPersonalRecord {
        BackupPersonalRecord(
            id: record.id,
            exerciseId: record.exercise?.id,
            exerciseName: record.exerciseName,
            weight: record.weight,
            weightUnit: record.weightUnit,
            date: record.date
        )
    }

    private static func makeBackupTemplate(_ template: WorkoutTemplate) -> BackupTemplate {
        BackupTemplate(
            id: template.id,
            name: template.name,
            parts: template.templateParts.sorted { $0.order < $1.order }.map(makeBackupTemplatePart)
        )
    }

    private static func makeBackupTemplatePart(_ part: TemplatePart) -> BackupTemplatePart {
        BackupTemplatePart(
            id: part.id,
            order: part.order,
            format: part.format,
            groups: part.groups.sorted { $0.order < $1.order }.map(makeBackupTemplateGroup)
        )
    }

    private static func makeBackupTemplateGroup(_ group: TemplateBlockGroup) -> BackupTemplateGroup {
        BackupTemplateGroup(
            id: group.id,
            order: group.order,
            rounds: group.rounds,
            blocks: group.blocks.sorted { $0.order < $1.order }.map(makeBackupTemplateBlock)
        )
    }

    private static func makeBackupTemplateBlock(_ block: TemplateBlock) -> BackupTemplateBlock {
        BackupTemplateBlock(
            id: block.id,
            order: block.order,
            exerciseId: block.exercise?.id,
            exerciseName: block.exerciseName,
            weight: block.weight,
            weightUnit: block.weightUnit,
            reps: block.reps,
            repsUnit: block.repsUnit,
            restSeconds: block.restSeconds,
            tagIds: block.tags.map(\.id)
        )
    }
}
