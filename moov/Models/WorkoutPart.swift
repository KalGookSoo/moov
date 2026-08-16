//
//  WorkoutPart.swift
//  moov
//

import Foundation
import SwiftData

/// 세션 내 하나의 수행 단위. 포맷과 결과는 세션이 아니라 파트에 귀속된다.
/// 한 세션에 여러 파트가 있을 수 있고, 파트마다 포맷/결과가 다를 수 있다. FR-02, FR-04.
@Model
final class WorkoutPart {
    var id: UUID
    var order: Int
    var format: WorkoutFormat
    var timeCapSeconds: Int?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseBlock.part)
    var blocks: [ExerciseBlock] = []
    /// 웜업처럼 결과를 남기지 않는 파트도 있을 수 있으므로 옵셔널이다.
    @Relationship(deleteRule: .cascade, inverse: \WorkoutResult.part)
    var result: WorkoutResult?
    var session: WorkoutSession?

    init(order: Int, format: WorkoutFormat, timeCapSeconds: Int? = nil) {
        self.id = UUID()
        self.order = order
        self.format = format
        self.timeCapSeconds = timeCapSeconds
    }
}
