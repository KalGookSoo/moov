//
//  Color+Hex.swift
//  moov
//

import SwiftUI

extension Color {
    /// "RRGGBB" 또는 "#RRGGBB" 형식의 문자열로부터 Color를 생성한다. Tag.colorHex 표시용.
    nonisolated init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }

        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b)
    }
}
