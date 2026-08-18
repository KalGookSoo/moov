//
//  TemplateApplier.swift
//  moov
//

import SwiftData

/// 템플릿의 파트/블록 구성을 세션에 복사해 채운다. TemplatePart → WorkoutPart,
/// TemplateBlock → ExerciseBlock으로 복사되며, 이후 자유롭게 수정할 수 있다.
/// docs/testing-strategy.md 유닛 테스트 대상. UC-06, FR-09.
enum TemplateApplier {
    static func apply(_ template: WorkoutTemplate, to session: WorkoutSession, using context: ModelContext) {
        let baseOrder = session.parts.count
        let templateParts = template.templateParts.sorted { $0.order < $1.order }

        for (offset, templatePart) in templateParts.enumerated() {
            let newPart = WorkoutPart(order: baseOrder + offset, format: templatePart.format)
            context.insert(newPart)
            session.parts.append(newPart)

            let templateGroups = templatePart.groups.sorted { $0.order < $1.order }
            for templateGroup in templateGroups {
                let newGroup = BlockGroup(order: newPart.groups.count, rounds: templateGroup.rounds)
                context.insert(newGroup)
                newPart.groups.append(newGroup)

                let templateBlocks = templateGroup.blocks.sorted { $0.order < $1.order }
                for templateBlock in templateBlocks {
                    // 템플릿 저장 당시 참조하던 종목이 카탈로그에서 삭제된 경우, 해당 블록은 건너뛴다.
                    guard let exercise = templateBlock.exercise else { continue }
                    let newBlock = ExerciseBlock(
                        order: newGroup.blocks.count,
                        exercise: exercise,
                        weight: templateBlock.weight,
                        weightUnit: templateBlock.weightUnit,
                        reps: templateBlock.reps,
                        repsUnit: templateBlock.repsUnit,
                        restSeconds: templateBlock.restSeconds,
                        tags: templateBlock.tags
                    )
                    context.insert(newBlock)
                    newGroup.blocks.append(newBlock)
                }
            }
        }
    }
}
