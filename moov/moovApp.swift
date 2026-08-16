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
        // UI 테스트는 실제 기기 저장소를 오염시키지 않도록 인메모리 저장소를 사용한다.
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            seedDefaultTagsIfNeeded(in: container)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // UI 테스트에서 온보딩/업데이트 안내 상태를 매번 초기 상태로 재현하기 위한 훅.
        if ProcessInfo.processInfo.arguments.contains("-uiTestResetState") {
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "lastSeenAppVersion")
        }
    }

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
