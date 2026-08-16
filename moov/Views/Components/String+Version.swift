//
//  String+Version.swift
//  moov
//

import Foundation

extension String {
    /// "1.0", "1.2.3" 형식의 버전 문자열을 숫자 기준으로 비교한다. FR-15.
    func isVersion(greaterThan other: String) -> Bool {
        guard !other.isEmpty else { return true }
        return self.compare(other, options: .numeric) == .orderedDescending
    }
}
