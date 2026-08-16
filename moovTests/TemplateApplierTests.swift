//
//  TemplateApplierTests.swift
//  moovTests
//

import Testing
import Foundation
import SwiftData
@testable import moov

struct TemplateApplierTests {
    @Test @MainActor func copiesPartsAndBlocksFromTemplate() throws {
        let context = TestSupport.makeContext()

        let exercise = Exercise(name: "Thruster")
        context.insert(exercise)
        let tag = Tag(name: "본운동")
        context.insert(tag)

        let template = WorkoutTemplate(name: "테스트 템플릿")
        context.insert(template)
        let templatePart = TemplatePart(order: 0, format: .forTime)
        context.insert(templatePart)
        template.templateParts.append(templatePart)
        templatePart.template = template

        let templateBlock = TemplateBlock(order: 0, exercise: exercise, weight: 43, weightUnit: .kg, reps: 21, tags: [tag])
        context.insert(templateBlock)
        templatePart.blocks.append(templateBlock)
        templateBlock.templatePart = templatePart

        let session = WorkoutSession(date: .now)
        context.insert(session)

        TemplateApplier.apply(template, to: session, using: context)

        #expect(session.parts.count == 1)
        let newPart = try #require(session.parts.first)
        #expect(newPart.format == .forTime)
        #expect(newPart.blocks.count == 1)

        let newBlock = try #require(newPart.blocks.first)
        #expect(newBlock.exercise?.name == "Thruster")
        #expect(newBlock.weight == 43)
        #expect(newBlock.weightUnit == .kg)
        #expect(newBlock.reps == 21)
        #expect(newBlock.tags.map(\.name) == ["본운동"])
    }

    @Test @MainActor func appendsAfterExistingPartsWithoutOverwriting() throws {
        let context = TestSupport.makeContext()

        let session = WorkoutSession(date: .now)
        context.insert(session)
        let existingPart = WorkoutPart(order: 0, format: .emom)
        context.insert(existingPart)
        session.parts.append(existingPart)
        existingPart.session = session

        let template = WorkoutTemplate(name: "템플릿")
        context.insert(template)
        let templatePart = TemplatePart(order: 0, format: .rounds)
        context.insert(templatePart)
        template.templateParts.append(templatePart)
        templatePart.template = template

        TemplateApplier.apply(template, to: session, using: context)

        #expect(session.parts.count == 2)
        #expect(session.parts.contains { $0.format == .emom })
        let appendedPart = try #require(session.parts.first { $0.format == .rounds })
        #expect(appendedPart.order == 1)
    }

    @Test @MainActor func skipsBlocksWhoseExerciseWasDeleted() throws {
        let context = TestSupport.makeContext()

        let exercise = Exercise(name: "Snatch")
        context.insert(exercise)

        let template = WorkoutTemplate(name: "템플릿")
        context.insert(template)
        let templatePart = TemplatePart(order: 0, format: .emom)
        context.insert(templatePart)
        template.templateParts.append(templatePart)
        templatePart.template = template

        let templateBlock = TemplateBlock(order: 0, exercise: exercise)
        context.insert(templateBlock)
        templatePart.blocks.append(templateBlock)
        templateBlock.templatePart = templatePart

        try context.save()
        context.delete(exercise)
        try context.save()

        let session = WorkoutSession(date: .now)
        context.insert(session)

        TemplateApplier.apply(template, to: session, using: context)

        #expect(session.parts.count == 1)
        #expect(session.parts.first?.blocks.isEmpty == true)
    }
}
