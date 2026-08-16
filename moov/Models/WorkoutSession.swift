//
//  WorkoutSession.swift
//  moov
//

import Foundation
import SwiftData

/// 세션(하루의 운동 기록) 단위. 순서가 있는 파트(WorkoutPart) 목록을 가지며,
/// 개수/순서에 제약이 없다. FR-01, FR-05.
@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade, inverse: \WorkoutPart.session)
    var parts: [WorkoutPart] = []
    @Relationship(deleteRule: .cascade, inverse: \ConditionNote.session)
    var conditionNotes: [ConditionNote] = []
    var notes: String?

    init(date: Date, notes: String? = nil) {
        self.id = UUID()
        self.date = date
        self.notes = notes
    }
}
