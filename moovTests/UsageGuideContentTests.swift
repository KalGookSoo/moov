//
//  UsageGuideContentTests.swift
//  moovTests
//

import Foundation
import Testing
@testable import moov

struct UsageGuideContentTests {
    @Test func topicsAreNotEmpty() {
        #expect(!UsageGuideContent.topics.isEmpty)
    }

    @Test func topicIDsAreUnique() {
        let ids = UsageGuideContent.topics.map(\.id)
        #expect(ids.count == Set(ids).count)
    }

    @Test func everyTopicHasTitleAndBody() {
        for topic in UsageGuideContent.topics {
            #expect(!topic.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!topic.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
