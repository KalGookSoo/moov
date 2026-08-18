//
//  WorkoutImporter.swift
//  moov
//

import Foundation
import SwiftData

/// 가져오기 JSON 최상위 구조. docs/import-format.md 참고. FR-22.
struct WorkoutImportPayload: Decodable {
    let sessions: [ImportSession]
}

struct ImportSession: Decodable {
    let date: String
    let notes: String?
    let parts: [ImportPart]
}

struct ImportPart: Decodable {
    let format: String
    let timeCapSeconds: Int?
    let groups: [ImportGroup]
}

struct ImportGroup: Decodable {
    let rounds: Int?
    let blocks: [ImportBlock]
}

struct ImportBlock: Decodable {
    let exercise: String
    let weight: Double?
    let weightUnit: String?
    let reps: Int?
    let repsUnit: String?
    let restSeconds: Int?
    let tags: [String]?
}

enum WorkoutImportError: LocalizedError {
    case emptySessions
    case emptyParts(sessionDate: String)
    case emptyGroups(sessionDate: String)
    case emptyBlocks(sessionDate: String)
    case invalidDate(String)
    case invalidFormat(String)
    case invalidWeightUnit(String)
    case invalidRepsUnit(String)

    var errorDescription: String? {
        switch self {
        case .emptySessions:
            "가져올 세션이 없습니다."
        case .emptyParts(let date):
            "\(date) 세션에 파트가 없습니다."
        case .emptyGroups(let date):
            "\(date) 세션에 그룹이 없는 파트가 있습니다."
        case .emptyBlocks(let date):
            "\(date) 세션에 블록이 없는 그룹이 있습니다."
        case .invalidDate(let value):
            "날짜 형식이 올바르지 않습니다: \(value) (yyyy-MM-dd)"
        case .invalidFormat(let value):
            "알 수 없는 포맷입니다: \(value)"
        case .invalidWeightUnit(let value):
            "알 수 없는 무게 단위입니다: \(value)"
        case .invalidRepsUnit(let value):
            "알 수 없는 반복수 단위입니다: \(value)"
        }
    }
}

/// 사용자가 작성한 정형 JSON을 세션으로 가져온다. 검증을 모두 마친 뒤에만 삽입하는
/// 원자적 가져오기다 — 하나라도 실패하면 아무것도 생성되지 않는다. FR-22.
enum WorkoutImporter {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// 가져온 세션 개수를 반환한다.
    @discardableResult
    static func apply(_ payload: WorkoutImportPayload, using context: ModelContext) throws -> Int {
        guard !payload.sessions.isEmpty else { throw WorkoutImportError.emptySessions }

        for importSession in payload.sessions {
            guard dateFormatter.date(from: importSession.date) != nil else {
                throw WorkoutImportError.invalidDate(importSession.date)
            }
            guard !importSession.parts.isEmpty else {
                throw WorkoutImportError.emptyParts(sessionDate: importSession.date)
            }
            for importPart in importSession.parts {
                guard WorkoutFormat(rawValue: importPart.format) != nil else {
                    throw WorkoutImportError.invalidFormat(importPart.format)
                }
                guard !importPart.groups.isEmpty else {
                    throw WorkoutImportError.emptyGroups(sessionDate: importSession.date)
                }
                for importGroup in importPart.groups {
                    guard !importGroup.blocks.isEmpty else {
                        throw WorkoutImportError.emptyBlocks(sessionDate: importSession.date)
                    }
                    for importBlock in importGroup.blocks {
                        if let unit = importBlock.weightUnit, WeightUnit(rawValue: unit) == nil {
                            throw WorkoutImportError.invalidWeightUnit(unit)
                        }
                        if let unit = importBlock.repsUnit, RepsUnit(rawValue: unit) == nil {
                            throw WorkoutImportError.invalidRepsUnit(unit)
                        }
                    }
                }
            }
        }

        var exercises = try context.fetch(FetchDescriptor<Exercise>())
        var tags = try context.fetch(FetchDescriptor<Tag>())

        for importSession in payload.sessions {
            let date = dateFormatter.date(from: importSession.date)!
            let session = WorkoutSession(date: date, notes: importSession.notes)
            context.insert(session)

            for (partOffset, importPart) in importSession.parts.enumerated() {
                let part = WorkoutPart(
                    order: partOffset,
                    format: WorkoutFormat(rawValue: importPart.format)!,
                    timeCapSeconds: importPart.timeCapSeconds
                )
                context.insert(part)
                session.parts.append(part)

                for (groupOffset, importGroup) in importPart.groups.enumerated() {
                    let group = BlockGroup(order: groupOffset, rounds: importGroup.rounds ?? 1)
                    context.insert(group)
                    part.groups.append(group)

                    for (blockOffset, importBlock) in importGroup.blocks.enumerated() {
                        let exercise = findOrCreateExercise(named: importBlock.exercise, in: &exercises, context: context)
                        let blockTags = (importBlock.tags ?? []).map {
                            findOrCreateTag(named: $0, in: &tags, context: context)
                        }
                        let block = ExerciseBlock(
                            order: blockOffset,
                            exercise: exercise,
                            weight: importBlock.weight,
                            weightUnit: importBlock.weightUnit.flatMap(WeightUnit.init),
                            reps: importBlock.reps,
                            repsUnit: importBlock.repsUnit.flatMap(RepsUnit.init),
                            restSeconds: importBlock.restSeconds,
                            tags: blockTags
                        )
                        context.insert(block)
                        group.blocks.append(block)
                    }
                }
            }
        }

        return payload.sessions.count
    }

    private static func findOrCreateExercise(named name: String, in exercises: inout [Exercise], context: ModelContext) -> Exercise {
        if let existing = exercises.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }
        let created = Exercise(name: name)
        context.insert(created)
        exercises.append(created)
        return created
    }

    private static func findOrCreateTag(named name: String, in tags: inout [Tag], context: ModelContext) -> Tag {
        if let existing = tags.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) {
            return existing
        }
        let created = Tag(name: name)
        context.insert(created)
        tags.append(created)
        return created
    }
}
