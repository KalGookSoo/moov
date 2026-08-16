//
//  WorkoutTemplate.swift
//  moov
//

import Foundation
import SwiftData

/// 재사용 가능한 운동 구성 템플릿. WorkoutPart/ExerciseBlock과 동일한 형태를 따르되
/// 수행 결과(WorkoutResult)가 없는 "설계도" 버전이다. 세션에 적용하면
/// TemplatePart → WorkoutPart, TemplateBlock → ExerciseBlock으로 복사되며,
/// 템플릿 삭제는 이미 복사되어 생성된 세션 데이터에 영향을 주지 않는다. FR-09.
@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \TemplatePart.template)
    var templateParts: [TemplatePart] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

@Model
final class TemplatePart {
    var id: UUID
    var order: Int
    var format: WorkoutFormat
    @Relationship(deleteRule: .cascade, inverse: \TemplateBlock.templatePart)
    var blocks: [TemplateBlock] = []
    var template: WorkoutTemplate?

    init(order: Int, format: WorkoutFormat) {
        self.id = UUID()
        self.order = order
        self.format = format
    }
}

@Model
final class TemplateBlock {
    var id: UUID
    var order: Int
    var exercise: Exercise?
    /// 기록 시점의 종목명 스냅샷. exercise가 삭제/개명되어도 템플릿에 표시할 이름은 유지된다.
    var exerciseName: String
    var weight: Double?
    var weightUnit: WeightUnit?
    var reps: Int?
    var sets: Int?
    var restSeconds: Int?
    @Relationship var tags: [Tag] = []
    var templatePart: TemplatePart?

    init(
        order: Int,
        exercise: Exercise,
        weight: Double? = nil,
        weightUnit: WeightUnit? = nil,
        reps: Int? = nil,
        sets: Int? = nil,
        restSeconds: Int? = nil,
        tags: [Tag] = []
    ) {
        self.id = UUID()
        self.order = order
        self.exercise = exercise
        self.exerciseName = exercise.name
        self.weight = weight
        self.weightUnit = weightUnit
        self.reps = reps
        self.sets = sets
        self.restSeconds = restSeconds
        self.tags = tags
    }
}
