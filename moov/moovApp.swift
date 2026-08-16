//
//  moovApp.swift
//  moov
//
//  Created by doyevskyi on 8/16/26.
//

import SwiftUI
import SwiftData

@main
struct moovApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutSession.self,
            WorkoutPart.self,
            ExerciseBlock.self,
            WorkoutResult.self,
            Exercise.self,
            Tag.self,
            PersonalRecord.self,
            ConditionNote.self,
            WorkoutTemplate.self,
            TemplatePart.self,
            TemplateBlock.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            seedDefaultTagsIfNeeded(in: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

/// 앱 최초 실행 시 웜업/본운동/보조운동 등 프리셋 태그를 시딩한다. docs/data-model.md 참고.
@MainActor
private func seedDefaultTagsIfNeeded(in container: ModelContainer) {
    let context = container.mainContext
    let existingCount = (try? context.fetchCount(FetchDescriptor<Tag>())) ?? 0
    guard existingCount == 0 else { return }

    for name in ["웜업", "본운동", "보조운동", "컨디셔닝", "스킬"] {
        context.insert(Tag(name: name))
    }
    try? context.save()
}
