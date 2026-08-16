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

    init(name: String, category: String? = nil, defaultWeightUnit: WeightUnit? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.defaultWeightUnit = defaultWeightUnit
    }
}
