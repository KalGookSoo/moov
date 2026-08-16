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

    var displayName: String {
        switch self {
        case .emom: "EMOM"
        case .amrap: "AMRAP"
        case .forTime: "For Time"
        case .interval: "인터벌"
        case .rounds: "라운드"
        case .strength: "스트렝스"
        }
    }
}

enum WeightUnit: String, Codable, CaseIterable {
    case lb
    case kg

    var displayName: String {
        switch self {
        case .lb: "lb"
        case .kg: "kg"
        }
    }
}

/// WorkoutResult가 어떤 필드를 사용하는지 구분한다.
enum ResultKind: String, Codable, CaseIterable {
    case time            // For Time / Interval
    case roundsAndReps   // AMRAP / Rounds
    case passFail        // EMOM 등
    case maxWeight        // Strength

    var displayName: String {
        switch self {
        case .time: "시간"
        case .roundsAndReps: "라운드 + 렙"
        case .passFail: "성공/실패"
        case .maxWeight: "최대 중량"
        }
    }

    /// 포맷 선택 시 기본으로 제안할 결과 유형. FR-04.
    static func suggested(for format: WorkoutFormat) -> ResultKind {
        switch format {
        case .forTime, .interval: .time
        case .amrap, .rounds: .roundsAndReps
        case .emom: .passFail
        case .strength: .maxWeight
        }
    }
}
