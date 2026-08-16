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
            Item.self,
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
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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
