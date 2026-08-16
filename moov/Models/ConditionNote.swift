//
//  ConditionNote.swift
//  moov
//

import Foundation
import SwiftData

/// 컨디션/부상 메모. 세션당 여러 개(부위별)를 허용한다. FR-08.
@Model
final class ConditionNote {
    var id: UUID
    var bodyPart: String?
    var painLevel: Int?
    var memo: String
    var session: WorkoutSession?

    init(bodyPart: String? = nil, painLevel: Int? = nil, memo: String) {
        self.id = UUID()
        self.bodyPart = bodyPart
        self.painLevel = painLevel
        self.memo = memo
    }
}
