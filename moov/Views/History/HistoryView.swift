//
//  HistoryView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 히스토리 탭 — 종목별/태그별 추이 진입점. UC-03.
struct HistoryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty && tags.isEmpty {
                    ContentUnavailableView {
                        Label("히스토리가 없어요", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("세션을 기록하면 종목별·태그별 추이를 확인할 수 있어요.")
                    }
                } else {
                    List {
                        if !filteredExercises.isEmpty {
                            Section("종목별") {
                                ForEach(filteredExercises) { exercise in
                                    NavigationLink {
                                        ExerciseHistoryView(exercise: exercise)
                                    } label: {
                                        Text(exercise.name)
                                    }
                                }
                            }
                        }

                        if !tags.isEmpty && searchText.isEmpty {
                            Section("태그별") {
                                ForEach(tags) { tag in
                                    NavigationLink {
                                        TagAggregateView(tag: tag)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(tag.colorHex.flatMap(Color.init(hex:)) ?? Color.secondary)
                                                .frame(width: 10, height: 10)
                                            Text(tag.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "종목 검색")
                }
            }
            .navigationTitle("히스토리")
        }
    }

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
