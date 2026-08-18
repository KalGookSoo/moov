//
//  BlockGroup.swift
//  moov
//

import Foundation
import SwiftData

/// 파트 안에서 함께 반복되는 블록 묶음. 블록이 1개면 스트레이트 세트, 2개 이상이면
/// 서킷(라운드마다 여러 종목을 번갈아 수행)을 뜻한다 — 별도의 방식 플래그 없이
/// 그룹에 속한 블록 수 자체가 구분을 표현한다. FR-20.
@Model
final class BlockGroup {
    var id: UUID
    var order: Int
    var rounds: Int
    @Relationship(deleteRule: .cascade, inverse: \ExerciseBlock.group)
    var blocks: [ExerciseBlock] = []
    var part: WorkoutPart?

    init(order: Int, rounds: Int = 1) {
        self.id = UUID()
        self.order = order
        self.rounds = rounds
    }
}
