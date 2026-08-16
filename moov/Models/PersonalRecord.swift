//
//  PersonalRecord.swift
//  moov
//

import Foundation
import SwiftData

/// 종목별 1RM 기록. append-only 로그로 관리하며, 별도의 "이전 값" 필드 없이
/// 이력 전체가 곧 로그다. 특정 종목의 "현재 PR"은 조회 시점에 최댓값으로 계산한다. FR-07.
@Model
final class PersonalRecord {
    var id: UUID
    var exercise: Exercise?
    /// 기록 시점의 종목명 스냅샷. exercise가 삭제/개명되어도 과거 기록의 종목명은 유지된다.
    var exerciseName: String
    var weight: Double
    var weightUnit: WeightUnit
    var date: Date

    init(exercise: Exercise, weight: Double, weightUnit: WeightUnit, date: Date) {
        self.id = UUID()
        self.exercise = exercise
        self.exerciseName = exercise.name
        self.weight = weight
        self.weightUnit = weightUnit
        self.date = date
    }
}
