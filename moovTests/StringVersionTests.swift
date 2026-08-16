//
//  StringVersionTests.swift
//  moovTests
//

import Testing
@testable import moov

struct StringVersionTests {
    @Test func higherVersionIsGreater() {
        #expect("1.1".isVersion(greaterThan: "1.0"))
    }

    @Test func equalVersionIsNotGreater() {
        #expect("1.0".isVersion(greaterThan: "1.0") == false)
    }

    @Test func lowerVersionIsNotGreater() {
        #expect("1.0".isVersion(greaterThan: "1.1") == false)
    }

    @Test func emptyBaselineIsAlwaysLower() {
        #expect("1.0".isVersion(greaterThan: ""))
    }

    @Test func multiComponentVersionsCompareNumerically() {
        // 사전순 비교였다면 "1.9" > "1.10"으로 잘못 판단했을 값
        #expect("1.10".isVersion(greaterThan: "1.9"))
    }
}
