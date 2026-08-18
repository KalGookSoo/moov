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
    @Relationship(deleteRule: .cascade, inverse: \TemplateBlockGroup.templatePart)
    var groups: [TemplateBlockGroup] = []
    var template: WorkoutTemplate?

    init(order: Int, format: WorkoutFormat) {
        self.id = UUID()
        self.order = order
        self.format = format
    }
}

/// `BlockGroup`의 템플릿 버전. 블록이 1개면 스트레이트 세트, 2개 이상이면 서킷을 뜻한다. FR-20.
@Model
final class TemplateBlockGroup {
    var id: UUID
    var order: Int
    var rounds: Int
    @Relationship(deleteRule: .cascade, inverse: \TemplateBlock.group)
    var blocks: [TemplateBlock] = []
    var templatePart: TemplatePart?

    init(order: Int, rounds: Int = 1) {
        self.id = UUID()
        self.order = order
        self.rounds = rounds
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
    var repsUnit: RepsUnit?
    var restSeconds: Int?
    @Relationship var tags: [Tag] = []
    var group: TemplateBlockGroup?

    init(
        order: Int,
        exercise: Exercise,
        weight: Double? = nil,
        weightUnit: WeightUnit? = nil,
        reps: Int? = nil,
        repsUnit: RepsUnit? = nil,
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
        self.repsUnit = repsUnit
        self.restSeconds = restSeconds
        self.tags = tags
    }
}
