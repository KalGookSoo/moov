//
//  ContentView.swift
//  moov
//
//  Created by doyevskyi on 8/16/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        SessionListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
