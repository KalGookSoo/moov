//
//  TestSupport.swift
//  moovTests
//

import Foundation
import SwiftData
@testable import moov

/// 유닛 테스트마다 격리된 인메모리 ModelContext를 만드는 공용 헬퍼. docs/testing-strategy.md 참고.
@MainActor
enum TestSupport {
    static func makeContext() -> ModelContext {
        let schema = Schema([
            WorkoutSession.self,
            WorkoutPart.self,
            BlockGroup.self,
            ExerciseBlock.self,
            WorkoutResult.self,
            Exercise.self,
            Tag.self,
            PersonalRecord.self,
            ConditionNote.self,
            WorkoutTemplate.self,
            TemplatePart.self,
            TemplateBlockGroup.self,
            TemplateBlock.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
