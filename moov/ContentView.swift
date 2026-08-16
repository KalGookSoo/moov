//
//  ContentView.swift
//  moov
//
//  Created by doyevskyi on 8/16/26.
//

import SwiftUI
import SwiftData

/// 앱 최상위 탭 구조. docs/information-architecture.md 참고.
struct ContentView: View {
    var body: some View {
        TabView {
            SessionListView()
                .tabItem {
                    Label("세션", systemImage: "figure.strengthtraining.traditional")
                }

            HistoryPlaceholderView()
                .tabItem {
                    Label("히스토리", systemImage: "chart.line.uptrend.xyaxis")
                }

            PersonalRecordPlaceholderView()
                .tabItem {
                    Label("PR", systemImage: "trophy")
                }

            ManageView()
                .tabItem {
                    Label("관리", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
