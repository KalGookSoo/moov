//
//  BackupImporter.swift
//  moov
//

import Foundation
import SwiftData

enum BackupImportError: LocalizedError {
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            "백업 파일 형식이 올바르지 않습니다."
        }
    }
}

/// 기존 데이터가 있을 때 백업을 어떻게 반영할지. FR-18.
enum BackupImportStrategy {
    /// 기존 데이터에 추가한다. 종목/태그는 ID 또는 이름으로 매칭해 중복 생성하지 않고,
    /// 세션/PR/템플릿은 이미 같은 ID가 있으면(재가져오기) 건너뛴다.
    case merge
    /// 기존 데이터를 모두 지운 뒤 백업 내용으로 되살린다.
    case replace
}

/// 백업 JSON(FR-17)을 읽어 데이터를 복원한다. docs/backup-format.md 참고. FR-18.
enum BackupImporter {
    static func hasExistingData(using context: ModelContext) throws -> Bool {
        try context.fetchCount(FetchDescriptor<WorkoutSession>()) > 0
            || context.fetchCount(FetchDescriptor<Exercise>()) > 0
            || context.fetchCount(FetchDescriptor<Tag>()) > 0
            || context.fetchCount(FetchDescriptor<WorkoutTemplate>()) > 0
            || context.fetchCount(FetchDescriptor<PersonalRecord>()) > 0
    }

    /// 새로 복원된 세션 개수를 반환한다.
    @discardableResult
    static func apply(_ payload: BackupPayload, strategy: BackupImportStrategy, using context: ModelContext) throws -> Int {
        switch strategy {
        case .replace:
            try deleteAllData(using: context)
        case .merge:
            break
        }

        var exercisesByID: [UUID: Exercise] = [:]
        var exercisesByName: [String: Exercise] = [:]
        for exercise in try context.fetch(FetchDescriptor<Exercise>()) {
            exercisesByID[exercise.id] = exercise
            exercisesByName[exercise.name.lowercased()] = exercise
        }

        var tagsByID: [UUID: Tag] = [:]
        var tagsByName: [String: Tag] = [:]
        for tag in try context.fetch(FetchDescriptor<Tag>()) {
            tagsByID[tag.id] = tag
            tagsByName[tag.name.lowercased()] = tag
        }

        func resolveExercise(id: UUID?, name: String) -> Exercise {
            if let id, let existing = exercisesByID[id] { return existing }
            if let existing = exercisesByName[name.lowercased()] { return existing }
            let created = Exercise(name: name)
            if let id { created.id = id }
            context.insert(created)
            exercisesByID[created.id] = created
            exercisesByName[name.lowercased()] = created
            return created
        }

        func resolveTag(id: UUID, name: String) -> Tag {
            if let existing = tagsByID[id] { return existing }
            if let existing = tagsByName[name.lowercased()] { return existing }
            let created = Tag(name: name)
            created.id = id
            context.insert(created)
            tagsByID[id] = created
            tagsByName[name.lowercased()] = created
            return created
        }

        // 카탈로그를 먼저 전부 반영해 세션/템플릿/PR이 그대로 참조하게 한다.
        // 이미 있는 항목의 카테고리/색상 등은 덮어쓰지 않는다(사용자가 그 사이 편집했을 수 있음).
        for backupExercise in payload.exercises {
            _ = resolveExercise(id: backupExercise.id, name: backupExercise.name)
        }
        for backupTag in payload.tags {
            _ = resolveTag(id: backupTag.id, name: backupTag.name)
        }

        let existingSessionIDs = Set(try context.fetch(FetchDescriptor<WorkoutSession>()).map(\.id))
        let existingRecordIDs = Set(try context.fetch(FetchDescriptor<PersonalRecord>()).map(\.id))
        let existingTemplateIDs = Set(try context.fetch(FetchDescriptor<WorkoutTemplate>()).map(\.id))

        var importedSessionCount = 0

        for backupSession in payload.sessions {
            guard !existingSessionIDs.contains(backupSession.id) else { continue }

            let session = WorkoutSession(date: backupSession.date, notes: backupSession.notes)
            session.id = backupSession.id
            context.insert(session)

            for backupNote in backupSession.conditionNotes {
                let note = ConditionNote(bodyPart: backupNote.bodyPart, painLevel: backupNote.painLevel, memo: backupNote.memo)
                note.id = backupNote.id
                context.insert(note)
                session.conditionNotes.append(note)
                note.session = session
            }

            for backupPart in backupSession.parts {
                let part = WorkoutPart(order: backupPart.order, format: backupPart.format, timeCapSeconds: backupPart.timeCapSeconds)
                part.id = backupPart.id
                context.insert(part)
                session.parts.append(part)
                part.session = session

                if let backupResult = backupPart.result {
                    let result = WorkoutResult(
                        kind: backupResult.kind,
                        timeSeconds: backupResult.timeSeconds,
                        rounds: backupResult.rounds,
                        extraReps: backupResult.extraReps,
                        isCompleted: backupResult.isCompleted,
                        maxWeight: backupResult.maxWeight,
                        completionNote: backupResult.completionNote
                    )
                    context.insert(result)
                    part.result = result
                    result.part = part
                }

                for backupGroup in backupPart.groups {
                    let group = BlockGroup(order: backupGroup.order, rounds: backupGroup.rounds)
                    group.id = backupGroup.id
                    context.insert(group)
                    part.groups.append(group)
                    group.part = part

                    for backupBlock in backupGroup.blocks {
                        let exercise = resolveExercise(id: backupBlock.exerciseId, name: backupBlock.exerciseName)
                        let blockTags = backupBlock.tagIds.compactMap { tagsByID[$0] }
                        let block = ExerciseBlock(
                            order: backupBlock.order,
                            exercise: exercise,
                            weight: backupBlock.weight,
                            weightUnit: backupBlock.weightUnit,
                            reps: backupBlock.reps,
                            repsUnit: backupBlock.repsUnit,
                            restSeconds: backupBlock.restSeconds,
                            tags: blockTags
                        )
                        block.id = backupBlock.id
                        block.exerciseName = backupBlock.exerciseName
                        context.insert(block)
                        group.blocks.append(block)
                        block.group = group
                    }
                }
            }

            importedSessionCount += 1
        }

        for backupRecord in payload.personalRecords {
            guard !existingRecordIDs.contains(backupRecord.id) else { continue }
            let exercise = resolveExercise(id: backupRecord.exerciseId, name: backupRecord.exerciseName)
            let record = PersonalRecord(
                exercise: exercise,
                weight: backupRecord.weight,
                weightUnit: backupRecord.weightUnit,
                date: backupRecord.date
            )
            record.id = backupRecord.id
            record.exerciseName = backupRecord.exerciseName
            context.insert(record)
        }

        for backupTemplate in payload.templates {
            guard !existingTemplateIDs.contains(backupTemplate.id) else { continue }

            let template = WorkoutTemplate(name: backupTemplate.name)
            template.id = backupTemplate.id
            context.insert(template)

            for backupPart in backupTemplate.parts {
                let part = TemplatePart(order: backupPart.order, format: backupPart.format)
                part.id = backupPart.id
                context.insert(part)
                template.templateParts.append(part)
                part.template = template

                for backupGroup in backupPart.groups {
                    let group = TemplateBlockGroup(order: backupGroup.order, rounds: backupGroup.rounds)
                    group.id = backupGroup.id
                    context.insert(group)
                    part.groups.append(group)
                    group.templatePart = part

                    for backupBlock in backupGroup.blocks {
                        let exercise = resolveExercise(id: backupBlock.exerciseId, name: backupBlock.exerciseName)
                        let blockTags = backupBlock.tagIds.compactMap { tagsByID[$0] }
                        let block = TemplateBlock(
                            order: backupBlock.order,
                            exercise: exercise,
                            weight: backupBlock.weight,
                            weightUnit: backupBlock.weightUnit,
                            reps: backupBlock.reps,
                            repsUnit: backupBlock.repsUnit,
                            restSeconds: backupBlock.restSeconds,
                            tags: blockTags
                        )
                        block.id = backupBlock.id
                        block.exerciseName = backupBlock.exerciseName
                        context.insert(block)
                        group.blocks.append(block)
                        block.group = group
                    }
                }
            }
        }

        return importedSessionCount
    }

    private static func deleteAllData(using context: ModelContext) throws {
        for session in try context.fetch(FetchDescriptor<WorkoutSession>()) { context.delete(session) }
        for template in try context.fetch(FetchDescriptor<WorkoutTemplate>()) { context.delete(template) }
        for record in try context.fetch(FetchDescriptor<PersonalRecord>()) { context.delete(record) }
        for tag in try context.fetch(FetchDescriptor<Tag>()) { context.delete(tag) }
        for exercise in try context.fetch(FetchDescriptor<Exercise>()) { context.delete(exercise) }
    }
}
