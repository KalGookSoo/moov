//
//  Enums.swift
//  moov
//

import Foundation

/// 파트(WorkoutPart)의 수행 방식. docs/data-model.md 참고.
enum WorkoutFormat: String, Codable, CaseIterable {
    case emom
    case amrap
    case forTime
    case interval
    case rounds
    case strength
}

enum WeightUnit: String, Codable, CaseIterable {
    case lb
    case kg
}

/// WorkoutResult가 어떤 필드를 사용하는지 구분한다.
enum ResultKind: String, Codable, CaseIterable {
    case time            // For Time / Interval
    case roundsAndReps   // AMRAP / Rounds
    case passFail        // EMOM 등
    case maxWeight        // Strength
}
