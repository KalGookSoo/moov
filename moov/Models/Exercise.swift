//
//  Exercise.swift
//  moov
//

import Foundation
import SwiftData

/// 사용자 정의 가능한 운동 종목 카탈로그. FR-11.
///
/// 종목을 삭제하면 참조(exercise)만 nil로 끊어지고(기본 deleteRule .nullify),
/// ExerciseBlock/TemplateBlock/PersonalRecord에 저장된 exerciseName 스냅샷으로
/// 과거 기록의 종목명이 그대로 유지된다.
@Model
final class Exercise {
    var id: UUID
    var name: String
    var category: String?
    var defaultWeightUnit: WeightUnit?

    // deleteRule은 "이 쪽이 삭제되면 상대편에 무엇을 할지"를 뜻하므로, exercise가 삭제됐을 때
    // 참조를 nil로 끊으려면 (ExerciseBlock 등이 아니라) 이 인버스 컬렉션 쪽에 선언해야 한다.
    @Relationship(deleteRule: .nullify, inverse: \ExerciseBlock.exercise)
    var exerciseBlocks: [ExerciseBlock] = []
    @Relationship(deleteRule: .nullify, inverse: \PersonalRecord.exercise)
    var personalRecords: [PersonalRecord] = []
    @Relationship(deleteRule: .nullify, inverse: \TemplateBlock.exercise)
    var templateBlocks: [TemplateBlock] = []

    init(name: String, category: String? = nil, defaultWeightUnit: WeightUnit? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.defaultWeightUnit = defaultWeightUnit
    }
}
