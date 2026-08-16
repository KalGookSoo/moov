//
//  PersonalRecordHistoryView.swift
//  moov
//

import SwiftUI
import SwiftData
import Charts

/// 특정 종목의 PR 갱신 이력 및 추이. UC-04, FR-07.
struct PersonalRecordHistoryView: View {
    let exerciseName: String

    @Environment(\.modelContext) private var modelContext
    @Query private var records: [PersonalRecord]

    init(exerciseName: String) {
        self.exerciseName = exerciseName
        _records = Query(filter: #Predicate<PersonalRecord> { $0.exerciseName == exerciseName })
    }

    private var timeline: [PRTimelineEntry] {
        PRTimelineCalculator.makeTimeline(from: records)
    }

    private var displayEntries: [PRTimelineEntry] {
        timeline.reversed()
    }

    var body: some View {
        Group {
            if timeline.isEmpty {
                ContentUnavailableView {
                    Label("기록이 없어요", systemImage: "trophy")
                } description: {
                    Text("PR을 등록하면 여기에 갱신 이력이 표시돼요.")
                }
            } else {
                List {
                    if timeline.count >= 2 {
                        Section("추이") {
                            PRTrendChart(entries: timeline)
                                .frame(height: 220)
                                .listRowInsets(EdgeInsets())
                                .padding()
                        }
                    }

                    Section("이력") {
                        ForEach(displayEntries) { entry in
                            PRRow(entry: entry)
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func deleteEntries(at offsets: IndexSet) {
        let entries = displayEntries
        for index in offsets {
            modelContext.delete(entries[index].record)
        }
    }
}

private struct PRTrendChart: View {
    let entries: [PRTimelineEntry]

    var body: some View {
        Chart(entries) { entry in
            LineMark(
                x: .value("날짜", entry.record.date, unit: .day),
                y: .value("중량", entry.record.weight)
            )
            PointMark(
                x: .value("날짜", entry.record.date, unit: .day),
                y: .value("중량", entry.record.weight)
            )
            .symbolSize(entry.isRecordBreaking ? 80 : 30)
        }
    }
}

private struct PRRow: View {
    let entry: PRTimelineEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.record.date, format: .dateTime.year().month().day())
                Text("\(entry.record.weight.formatted())\(entry.record.weightUnit.displayName)")
                    .font(.headline)
            }
            Spacer()
            if entry.isRecordBreaking {
                Label("갱신", systemImage: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        PersonalRecordHistoryView(exerciseName: "Back Squat")
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
