//
//  Tag.swift
//  moov
//

import Foundation
import SwiftData

/// 사용자 정의 가능한 태그 카탈로그 (웜업/본운동/보조운동 등). FR-10, FR-12.
@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String?

    init(name: String, colorHex: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
    }
}
