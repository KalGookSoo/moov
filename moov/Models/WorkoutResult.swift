//
//  WorkoutResult.swift
//  moov
//

import Foundation
import SwiftData

/// 파트(WorkoutPart)의 수행 결과. kind에 따라 사용하는 필드가 다르다. FR-04.
@Model
final class WorkoutResult {
    var id: UUID
    var kind: ResultKind
    var timeSeconds: Int?       // For Time / Interval
    var rounds: Int?            // AMRAP / Rounds
    var extraReps: Int?         // 마지막 미완료 라운드의 추가 렙
    var isCompleted: Bool?      // EMOM 등 성공/실패 여부
    var maxWeight: Double?      // Strength 최대 중량
    var completionNote: String? // 서술형 보충 설명
    var part: WorkoutPart?

    init(
        kind: ResultKind,
        timeSeconds: Int? = nil,
        rounds: Int? = nil,
        extraReps: Int? = nil,
        isCompleted: Bool? = nil,
        maxWeight: Double? = nil,
        completionNote: String? = nil
    ) {
        self.id = UUID()
        self.kind = kind
        self.timeSeconds = timeSeconds
        self.rounds = rounds
        self.extraReps = extraReps
        self.isCompleted = isCompleted
        self.maxWeight = maxWeight
        self.completionNote = completionNote
    }
}
