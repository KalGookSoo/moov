//
//  PersonalRecordListView.swift
//  moov
//

import SwiftUI
import SwiftData

/// PR 탭 — 종목별 최고 기록 목록. UC-04, FR-07.
struct PersonalRecordListView: View {
    @Query(sort: \PersonalRecord.date, order: .reverse) private var records: [PersonalRecord]

    @State private var isAddingRecord = false

    var body: some View {
        NavigationStack {
            Group {
                if groupedRecords.isEmpty {
                    ContentUnavailableView {
                        Label("등록된 PR이 없어요", systemImage: "trophy")
                    } description: {
                        Text("종목별 최고 기록을 등록하고 갱신 추이를 확인해보세요.")
                    } actions: {
                        Button("PR 등록") { isAddingRecord = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(groupedRecords) { group in
                            NavigationLink {
                                PersonalRecordHistoryView(exerciseName: group.exerciseName)
                            } label: {
                                PRGroupRow(group: group)
                            }
                        }
                    }
                }
            }
            .navigationTitle("PR")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingRecord = true
                    } label: {
                        Label("PR 등록", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingRecord) {
                NavigationStack {
                    PersonalRecordFormView()
                }
            }
        }
    }

    private var groupedRecords: [ExercisePRGroup] {
        Dictionary(grouping: records, by: { $0.exerciseName })
            .map { name, recs in
                ExercisePRGroup(
                    exerciseName: name,
                    best: recs.max { $0.weight < $1.weight }!,
                    lastUpdated: recs.map(\.date).max() ?? .distantPast
                )
            }
            .sorted { $0.exerciseName < $1.exerciseName }
    }
}

private struct ExercisePRGroup: Identifiable {
    let exerciseName: String
    let best: PersonalRecord
    let lastUpdated: Date
    var id: String { exerciseName }
}

private struct PRGroupRow: View {
    let group: ExercisePRGroup

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.exerciseName)
                    .font(.headline)
                Text("최근 갱신: \(group.lastUpdated.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(group.best.weight.formatted())\(group.best.weightUnit.displayName)")
                .font(.title3.bold())
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PersonalRecordListView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
