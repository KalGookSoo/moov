//
//  ExerciseBlock.swift
//  moov
//

import Foundation
import SwiftData

/// 종목 단위 블록. 하나 이상의 태그로 웜업/본운동/보조운동 등을 구분한다. FR-03, FR-10.
@Model
final class ExerciseBlock {
    var id: UUID
    var order: Int
    var exercise: Exercise?
    /// 기록 시점의 종목명 스냅샷. exercise가 삭제/개명되어도 과거 기록의 종목명은 유지된다.
    var exerciseName: String
    var weight: Double?
    var weightUnit: WeightUnit?
    var reps: Int?
    var sets: Int?
    var restSeconds: Int?
    @Relationship var tags: [Tag] = []
    var part: WorkoutPart?

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
